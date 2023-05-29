require "config"
require "fileutils"
require "colored2"
require "print"
module Flutter
  class Produce
    def insert_swift_version
      file_path = Config.instance.xcconfig_path
      File.open(file_path, "a") do |file|
        file.puts(Config.instance.swift_version)
      end
    end

    def insert_source
      source = Flutter::Config.instance.source
      podfile_path = Flutter::Config.instance.podfile_path
      podfiles = File.readlines(podfile_path)
      # 插入source源
      podfiles.insert(0, source)
      # 把修改的内容写回原文件
      File.open(podfile_path, "w") { |file| file.puts(podfiles) }
    end

    def podfile_content
      File.readlines(Config.instance.podfile_path)
    end

    # 目标字符串的行号
    def target_line
      # 读取原始文件内容，存放到数组中
      file_lines = podfile_content
      # 目标字符串
      target_str = "flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))"
      # 目标字符串行号
      file_lines.index do |line|
        line.include?(target_str)
      end
    end

    def insert_router
      # 获取目标字符串的行号
      target_file_num = target_line

      file_lines = podfile_content
      return unless target_file_num

      # 向目标字符串的下一行插入新字符串
      file_lines.insert(target_file_num + 1, Config.instance.router_name)
      # 将修改后的内容写回文件
      File.open(Config.instance.podfile_path, "w") do |file|
        file.puts(file_lines)
      end
    end

    def clean
      unless Flutter::Config.instance.ignore_gp
        # 清空当前的工作目录
        `git checkout .`
        # 更新内容
        `git pull`
      end

      # 清空flutter，并且更新依赖
      if Flutter::Config.instance.debug
        flutter_cmd = File.expand_path(File.join("~/.flutter_sdks/3.7.12", "bin", "flutter"))
        system("#{flutter_cmd} clean && #{flutter_cmd} pub get")
        system("#{flutter_cmd} pub upgrade")
      else
        system("flutter clean && flutter pub get")
        system("flutter pub upgrade")
      end
    end

    # 获取项目指定flutter SDK版本的SDK路径
    # eg: ~/.flutter_sdks/#{version}
    def flutter_root
      generated_xcode_build_settings_path = File.expand_path(File.join(".ios", "Flutter", "Generated.xcconfig"), Dir.pwd)
      unless File.exist?(generated_xcode_build_settings_path)
        raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
      end

      File.foreach(generated_xcode_build_settings_path) do |line|
        matches = line.match(/FLUTTER_ROOT=(.*)/)
        return matches[1].strip if matches
      end
      # This should never happen...
      raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
    end
    private :target_line, :insert_swift_version, :podfile_content, :insert_router, :clean, :insert_source, :flutter_root

    def setup
      project_dir = Config.instance.project_dir
      # 切换到指定项目目录
      Dir.chdir(project_dir) if project_dir
      clean
      # insert_source
      insert_swift_version
      insert_router
    end

    def build
      # 创建framework存放目录
      framework_path = Flutter::Config.instance.framework_path
      FileUtils.mkdir_p(framework_path) unless Dir.exist?(framework_path)
      config = Config.instance.config
      flutter_cmd = File.expand_path(File.join(flutter_root, "bin", "flutter"))
      if config
        if config.casecmp("debug").zero?
          system("#{flutter_cmd} build ios-framework --xcframework --no-universal --no-tree-shake-icons --debug --no-profile --no-release --output=#{Flutter::Config.instance.framework_path}")
        elsif config.casecmp("profile").zero?
          system("#{flutter_cmd} build ios-framework --xcframework --no-universal --no-tree-shake-icons --profile --no-debug --no-release --output=#{Flutter::Config.instance.framework_path}")
        elsif config.casecmp("release").zero?
          system("#{flutter_cmd} build ios-framework --xcframework --no-universal --no-tree-shake-icons --release --no-debug --no-profile --output=#{Flutter::Config.instance.framework_path}")
        else
          raise "请指定正确的构建类型（debug/profile/release）".red
        end
      else
        # 构建所有环境的包（debug、profile、release)
        system("#{flutter_cmd} build ios-framework --xcframework --no-universal --no-tree-shake-icons --output=#{Flutter::Config.instance.framework_path}")
      end
    end

    def log
      # 产物类型
      product_type = if !Flutter::Config.instance.config
                       "所有类型(debug/profile/release)"
                     else
                       Flutter::Config.instance.config
                     end
      # 产物路径
      product_path = if !Flutter::Config.instance.config
                       File.expand_path(Flutter::Config.instance.framework_path, Dir.pwd)
                     else
                       File.expand_path(File.join(Flutter::Config.instance.framework_path, "#{product_type}"), Dir.pwd)
                     end

      # 产物数量
      product_num = if !Flutter::Config.instance.config
                      Dir.glob("#{File.join(product_path, "Debug")}/*").size
                    else
                      Dir.glob("#{product_path}/*").size
                    end
      Flutter::Print.print_product_info(product_type, product_num, product_path)

      # 产物
      products = Dir.glob(File.join(product_path, "*.xcframework")).map do |file|
        File.basename(file)
      end
      Flutter::Config.instance.new_products = products
      puts "\n"
      pro_str = ""
      products.each do |ele|
        pro_str = pro_str + ele + "\n"
      end
      pro_str = pro_str.rstrip
      return if pro_str.empty?

      Flutter::Print.print_all_products(pro_str)
    end
  end
end
