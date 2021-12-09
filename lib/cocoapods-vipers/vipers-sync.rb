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

module CocoapodsVipers
    class Vipers
        def sync(paths)
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

          should_check = false
          if json['check_json'] == 'true'
            should_check = true
          end

          # Pod::UI.puts "json: #{json}"
          # Pod::UI.puts "ext_path: #{ext_path}"
          # Pod::UI.puts "pod_paths: #{paths}"

          # vipers_case = []
          vipers_create_binder = []
          vipers_params_class = []
          vipers_ext_func = []

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

              # vipers_case.push("// MARK: - #{data_hash["moduleName"]} #{data_hash["description"]}")
              vipers_create_binder.push("    // MARK: - #{data_hash["moduleName"]} Create Binder")
              vipers_params_class.push("  // MARK: - #{data_hash["moduleName"]} Params Class\n")
              vipers_ext_func.push("  // MARK: - #{data_hash["moduleName"]} Extension Func\n")

              cls_array = []
              vipers.each do |viper|
                # vipers_case.push("    case #{viper["viper"]}")
                handleClsAndMethod(viper, vipers_params_class, vipers_ext_func)
                if spec['spec_name'] == main_project_vipers_json_path
                  vipers_create_binder.push("      //#{viper["description"]}\n      VIPERBinder.addUnity(className: \"#{viper["class"]}\", identifier: VIPERs.#{viper["viper"]}.identifier)")
                else
                  vipers_create_binder.push("      //#{viper["description"]}\n      VIPERBinder.addUnity(projectClassName: \"#{data_hash["moduleName"]}.#{viper["class"]}\", identifier: VIPERs.#{viper["viper"]}.identifier)")
                end
                cls_array.push(viper["class"])
              end
              vipers_create_binder.push("\n")

              if should_check
                # --check
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

          # injection_vipers_case = vipers_case.join("\n")
          injection_vipers_params_class = vipers_params_class.join("\n")
          injection_vipers_ext_func = vipers_ext_func.join("\n")
          injection_vipers_create_binder = vipers_create_binder.join("\n")

          template_file = ''
          
          if extension_template_path
            template_file = extension_template_path
          else
            template_file = File.dirname(__FILE__) + '/template/Vipers+Extension.swift' # 脚本所在目录 寻找模板文件
          end
          
          template = File.read(template_file)

          # 替换 /** Injection VIPERS case **/ （暂不执行）
          template.gsub!("/** Injection VIPERBinderHelper autoCreateBinder **/", injection_vipers_create_binder)
          template.gsub!("/** Injection VIPERs extension **/", injection_vipers_ext_func)
          template.gsub!("/** Injection VIPERParams class **/", injection_vipers_params_class)              

          File.open(ext_path, "w") { |file| file.puts template }

          # 1 校验没有重复的 枚举值 enum
          # 2 读取模板的swift文件
          # 3 遍历读取模块里的json ps: 主工程 + 业务工程
          # 4 主工程的目标文件(HycanService下的) 注入各个模块绑定语句以及参数方法

        end
    end
end
