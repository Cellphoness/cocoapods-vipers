require 'cocoapods'
require 'fileutils'
require 'yaml'
require 'json'

def handleClsAndMethod(viper, vipers_params_class, vipers_ext_func)  

  if !viper["params"] || viper["params"].empty?
    return
  end

  var_lines = []
  assign_lines = []
  init_params = [] #id: Int, path: String = "/", ids: Array<Int>
  return_types = []
  parmas_desc = []
  return_args = []

  viper["params"].each do |key, value|
    defaultValue = ''
    ketType = value["type"]
    if value["default"] != nil
      if ketType == 'String' || ketType == 'NSString'
        defaultValue = " = \"#{value["default"]}\""
      else
        defaultValue = " = #{value["default"]}"
      end        
    end
    return_types.push("(#{ketType})")
    parmas_desc.push("    ///   - #{key}: #{value["description"]}")
    init_params.push("#{key}: #{ketType}#{defaultValue}")
    var_lines.push("    public var #{key}: #{ketType}#{defaultValue}")
    assign_lines.push("      self.#{key} = #{key}")
    return_args.push("#{key}: #{key}")
  end 

  var_lines_text = var_lines.join("\n")
  assign_lines_text = assign_lines.join("\n")
  init_params_text = init_params.join(", ")
  init_params_text_line = "    public required init(#{init_params_text}) {"

  class_text = <<-RUBY
  // MARK: - VIPERParams.#{viper["viper"]}
  public class #{viper["viper"]}: Base {
#{var_lines_text}
#{init_params_text_line}
#{assign_lines_text}
    }
    required public init() {
        fatalError("init() has not been implemented")
    }
  }
RUBY
  init_params_text_method = "    public func #{viper["viper"]}Params(#{init_params_text}) -> VIPERParams.#{viper["viper"]} {"
  curry_return = "      return curry(#{viper["viper"]}Params)"
  curry_return_type = ": #{return_types.join(' -> ')} -> VIPERParams.#{viper["viper"]} {"
  method_text = <<-RUBY
    // MARK: - Methods of #{viper["viper"]}
    /// #{viper["description"]}
    public func #{viper["viper"]}() -> Self {
        return .#{viper["viper"]}
    }

    /// #{viper["description"]}页面参数列表
    /// - Parameters:
#{parmas_desc.join("\n")}
    /// - Returns: 页面参数对象
#{init_params_text_method}
      return VIPERParams.#{viper["viper"]}(#{return_args.join(", ")})
    }

    /// #{viper["description"]}页面参数 柯里化
    public var #{viper["viper"]}Curry#{curry_return_type}
#{curry_return}
    }
RUBY

  vipers_params_class.push(class_text) 
  vipers_ext_func.push(method_text)
end

def traverse_dir(file_path)
  if File.directory? file_path
    Dir.foreach(file_path) do |file|
      if file != "." && file != ".."
        traverse_dir(file_path + "/" + file){|x| yield x}
      end
    end
  else
    yield file_path
  end
end

# 返回 { Bool, String } 是否存在重复的viper
def check_duplicate_viper(paths, main_path, vipers_json_path) 
  arr = []
  paths.each do |spec|
    json_path = ''
    if spec['spec_name'] == main_path
      json_path = spec['spec_name']
    else
      spec_json_path = "#{vipers_json_path}"
      spec_json_path.gsub!("SPECNAME", spec['spec_name'])
      json_path = spec['spec_path'] + "/" + spec_json_path
    end
  
    if File.exists?(json_path)
      file = File.read(json_path)
      data_hash = JSON.parse(file)
      vipers = data_hash["vipers"]

      vipers.each do |viper|
        arr.push(viper["viper"])
      end              
    
    end
  end

  result = arr.detect {|e| arr.rindex(e) != arr.index(e) }

  if result
    return { 'result' => true, 'viper' => result }
  else
    return { 'result' => false }
  end

end

module CocoapodsVipers
    class Vipers
        def sync(paths, pods)
          Pod::UI.puts "Synchronizing Vipers yml"
          
          if !File.exists?("vipers_config.yml")
            Pod::UI.puts "vipers_config.yml not found"
            return
          end
          
          json = YAML.load(File.open("vipers_config.yml"))
          ext_path = json['hycan_service_injects_extension_path']
          vipers_json_path = json['podspec_project_vipers_json_path']
          main_project_vipers_json_path = json['main_project_vipers_json_path']
          extension_template_path = json['extension_template_path']
          prorocols_template_path = json['prorocols_template_path']
          protocols_path = json['hycan_service_injects_protocols_path']
          pod_frameworks_all_path = json['pod_frameworks_all_path']

          flag = check_duplicate_viper(paths, main_project_vipers_json_path, vipers_json_path)

          if flag['result']
            raise "viper脚本执行失败，出现重复定义的viper: #{flag['viper']}"
          end

          check_unused_pods = false

          if json['check_unused_pods'] == 'true'
            check_unused_pods = true
          end

          framework_array = pods

          if pod_frameworks_all_path 
            if File.exists?(pod_frameworks_all_path)
              fileData = File.read(pod_frameworks_all_path)
              all_framework = JSON.parse(fileData)
              framework_array = all_framework
            end
          end

          should_check = false
          if json['check_json'] == 'true'
            should_check = true
          end

          # Pod::UI.puts "json: #{json}"
          # Pod::UI.puts "ext_path: #{ext_path}"
          # Pod::UI.puts "pod_paths: #{paths}"

          vipers_case = []
          vipers_create_binder = []
          vipers_params_class = []
          vipers_ext_func = []
          vipers_call_binder = []

          if !paths
            Pod::UI.puts "没有找到对应的业务组件，以Hycan开头的"
            return
          end

          paths.insert(0, { 'spec_path' => '', 'spec_name' => main_project_vipers_json_path})
          
          paths.each do |spec|
            # puts "spec: #{spec}"
            spec_path = spec['spec_path']
            json_path = ''
            spec_json_path = ''
        
            if spec['spec_name'] == main_project_vipers_json_path
              json_path = spec['spec_name']
            else
              spec_json_path = "#{vipers_json_path}"
              spec_json_path.gsub!("SPECNAME", spec['spec_name'])
              json_path = spec_path + "/" + spec_json_path
            end

            if !File.exists?(json_path)
              Pod::UI.puts "没有找到对应#{json_path}下的路由json"
            else
                      
              file = File.read(json_path)
              data_hash = JSON.parse(file)
              vipers = data_hash["vipers"]

              vipers_case.push("// MARK: - #{data_hash["moduleName"]} #{data_hash["description"]}")
              vipers_create_binder.push("    // MARK: - #{data_hash["moduleName"]} Create Binder")
              vipers_params_class.push("  // MARK: - #{data_hash["moduleName"]} Params Class\n")
              vipers_ext_func.push("  // MARK: - #{data_hash["moduleName"]} Extension Func\n")
              vipers_call_binder.push("        init#{data_hash["moduleName"]}Binder()")
              vipers_create_binder.push("   public static func init#{data_hash["moduleName"]}Binder() {")
              cls_array = []
              vipers.each do |viper|
                if viper["description"] == ""
                  vipers_case.push("    case #{viper["viper"]}")
                else
                  vipers_case.push("    //#{viper["description"]}\n    case #{viper["viper"]}")
                end
                handleClsAndMethod(viper, vipers_params_class, vipers_ext_func)
                if spec['spec_name'] == main_project_vipers_json_path
                  vipers_create_binder.push("      //#{viper["description"]}\n      VIPERBinder.addUnity(className: \"#{viper["class"]}\", identifier: VIPERs.#{viper["viper"]}.identifier)")
                else
                  vipers_create_binder.push("      //#{viper["description"]}\n      VIPERBinder.addUnity(projectClassName: \"#{data_hash["moduleName"]}.#{viper["class"]}\", identifier: VIPERs.#{viper["viper"]}.identifier)")
                end
                cls_array.push(viper["class"])
              end
              vipers_case.push("\n")
              vipers_create_binder.push("   }\n")

              # 检测模块内未使用的Pods-framework
              if check_unused_pods
                # Pod::UI.puts "检测模块内未使用的Pods-framework"
                dir_path = spec_path + '/' + data_hash["moduleName"]
                if spec['spec_name'] == main_project_vipers_json_path
                  dir_path = '.' + '/HycanCommunity/Swift'
                end

                traverse_dir(dir_path) { |f|
                  if f.to_s() =~ /\.swift$/ || f.to_s() =~ /\.h$/ || f.to_s() =~ /\.m$/
                    lineNumber = 0
                    IO.readlines(f).each { |line| 
                      framework_array.each do |framew|
                        if line =~ /^[\/\/]/
                        else
                          if line.index("#import <#{framew}")
                            # Pod::UI.puts "in file: #{f} - line in #{data_hash["moduleName"]}"
                            # Pod::UI.puts line
                            framework_array.delete(framew)
                            break
                          end
  
                          if line.index("import #{framew}")
                            # Pod::UI.puts "in file: #{f} - line in #{data_hash["moduleName"]}"
                            # Pod::UI.puts line
                            framework_array.delete(framew)
                            break
                          end
                        end
                      end
                      if lineNumber > 200
                        break
                      end
                      lineNumber += 1
                    }
                  end                  
                }
              end

              # 检测模块内是否有未定义的 class
              if should_check
                # Pod::UI.puts "检测模块内是否有未定义的 class"                 
                dir_path = spec_path + '/' + data_hash["moduleName"]
                if spec['spec_name'] == main_project_vipers_json_path
                  dir_path = '.' + '/HycanCommunity/Swift'
                end
                traverse_dir(dir_path) { |f|
                  if f.to_s() =~ /\.swift$/
                    lineNumber = 0
                    IO.readlines(f).each { |line| 
                      cls_array.each do |cls|
                        if line.index("class #{cls}")
                          cls_array.delete(cls)
                          break
                        end
                      end
                      if lineNumber > 100
                        break
                      end
                      lineNumber += 1
                    }
                  end                  
                }

                Pod::UI.puts "以下 Class 在 #{data_hash["moduleName"]} 没找到定义"
                Pod::UI.puts cls_array.to_s()
              end
          
            end
          end

          if check_unused_pods
            Pod::UI.puts "以下 Pod 的 Framework 在主工程+Pod工程都没找到定义"
            Pod::UI.puts framework_array.to_s()
          end

          injection_vipers_case = vipers_case.join("\n")
          injection_vipers_params_class = vipers_params_class.join("\n")
          injection_vipers_ext_func = vipers_ext_func.join("\n")
          injection_vipers_create_binder = vipers_create_binder.join("\n")
          injection_vipers_call_binder = vipers_call_binder.join("\n")

          template_file = ''
          
          if extension_template_path
            template_file = extension_template_path
          else
            template_file = File.dirname(__FILE__) + '/template/Vipers+Extension.swift' # 脚本所在目录 寻找模板文件
          end
          
          template = File.read(template_file)
          template.gsub!("/** Injection VIPERBinderHelper autoCreateBinder init **/", injection_vipers_create_binder)
          template.gsub!("/** Injection VIPERs extension **/", injection_vipers_ext_func)
          template.gsub!("/** Injection VIPERParams class **/", injection_vipers_params_class)              

          File.open(ext_path, "w") { |file| file.puts template }

          prorocols_template_file = ''
          
          if prorocols_template_path
            prorocols_template_file = prorocols_template_path
          else
            prorocols_template_file = File.dirname(__FILE__) + '/template/Protocols.swift' # 脚本所在目录 寻找模板文件
          end
          
          prorocols_template = File.read(prorocols_template_file)
          prorocols_template.gsub!("/** Injection VIPERS case **/", injection_vipers_case)
          prorocols_template.gsub!("/** Injection VIPERBinderHelper call init function **/", injection_vipers_call_binder)
          File.open(protocols_path, "w") { |file| file.puts prorocols_template }

          # 1 校验没有重复的 枚举值 enum
          # 2 读取模板的swift文件
          # 3 遍历读取模块里的json ps: 主工程 + 业务工程
          # 4 主工程的目标文件(HycanService下的) 注入各个模块绑定语句以及参数方法

        end
    end
end
