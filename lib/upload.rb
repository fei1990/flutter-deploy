# frozen_string_literal: true

module Flutter
  class Upload
    def initialize
      # project_dir = Config.instance.project_dir
      # # 切换到指定项目目录
      # Dir.chdir(project_dir) if project_dir
      # spec name
      @spec_name = "ios_sohu_spec"
      # pec库远程地址
      @spec_url = "git@code.sohuno.com:mtpc_sh_ios/ios_sohu_spec.git"
      # SoHuHost远程仓库地址
      @framework_url = "git@code.sohuno.com:MOBILE-BASIC/SoHuHost.git"
      @sohu_host_project_name = "SoHuHost"
      # 手搜framework local地址（从远程clone到本地）
      @framework_localPath = File.expand_path(File.join("..", "#{@sohu_host_project_name}"), Dir.pwd)
      # 手搜spec文件名
      @podspec_name = "#{@sohu_host_project_name}.podspec"
      # spec文件路径
      @spec_path = File.expand_path(File.join("#{@framework_localPath}", "#{@podspec_name}"), Dir.pwd)

      # 产物的类型  debug/profile/release
      @product_type = Flutter::Config.instance.config

      @product_map = { 1 => "Debug", 2 => "Profile", 3 => "Release" }
      # 用于记录旧的构建产物
      @origin_products = []
    end

    # 上传
    def upload
      update_host
      copy_products
      modify_podspec_file
      origin_version = get_origin_version
      new_version = gen_new_version(origin_version)
      update_version(new_version)
      push_to_remote(new_version)
    end

    def log_products_diff
      return unless !Flutter::Config.instance.new_products.empty? && !@origin_products.empty?

      diff = Flutter::Config.instance.new_products.size > @origin_products.size ? Flutter::Config.instance.new_products.diffence(@origin_products) : @origin_products.difference(Flutter::Config.instance.new_products)
      return if diff.empty?

      diff_str = ""
      diff.each { |ele| diff_str = diff_str + ele + "\n" }
      diff_str = diff_str.rstrip
      if Flutter::Config.instance.new_products.size > @origin_products.size
        print TTY::Box.info "产物新增了：\n#{diff_str}"
      elsif Flutter::Config.instance.new_products.size < @origin_products.size
        print TTY::Box.info "产物减少了：\n#{diff_str}"
      end
    end

    # 更新下本地SoHuHost
    def update_host
      if !Dir.exist?(@framework_localPath)
        # 执行Git clone
        system("git clone #{@framework_url} #{@framework_localPath}")
      else
        # 执行 git pull
        system("git -C #{@framework_localPath} checkout .")
        system("git -C #{@framework_localPath} pull")
      end
    end

    def check_build_type
      return unless !@product_type || @product_type.empty?

      puts "您构建了多个类型的产物："
      puts "[1]: debug"
      puts "[2]: profile"
      puts "[3]: release"
      print "请选择一个上传（退出，请选择'q/Q'）："
      input = $stdin.gets.chomp
      exit if input.casecmp("q").zero?
      @product_type = @product_map[input.to_i]
      return if @product_type

      print TTY::Box.error("请选择正确的构建类型")
      exit
    end

    # 获得产物路径
    def path_for_product
      check_build_type
      source_dir = File.expand_path(File.join(Flutter::Config.instance.framework_path, @product_type.capitalize), Dir.pwd)
    end

    # 将产物copy到@framework_localPath目录下
    def copy_products
      # 先记录下旧的产物，用于比较是否有更新
      @origin_products = Dir.glob(File.join(@framework_localPath, "*.xcframework")).map do |file|
        File.basename(file)
      end

      # 如果有则删之
      system("find #{@framework_localPath} -name 'Debug' | xargs rm -rf")
      system("find #{@framework_localPath} -name 'Profile' | xargs rm -rf")
      system("find #{@framework_localPath} -name 'Release' | xargs rm -rf")
      system("find #{@framework_localPath} -name 'iphoneos' | xargs rm -rf")
      system("find #{@framework_localPath} -name 'iphonesimulator' | xargs rm -rf")
      # 1、先移除旧的framework
      xcframework_files = Dir.glob(File.join(@framework_localPath, "*.xcframework"))
      xcframework_files.each do |xc_file|
        # FileUtils.rm(xc_file)
        system("rm -rf #{xc_file}")
      end
      # 2、将新产物move到@framework_localPath目录下
      source_dir = path_for_product

      # 获取源文件夹下的所有.xcframework文件
      xc_files = Dir.glob(File.join(source_dir, "*"))
      raise "当前产物路径：#{source_dir}为空，\n请先构建需要的产物" unless xc_files.any?

      # 移动到目标文件夹下
      xc_files.each do |file|
        FileUtils.mv(file, @framework_localPath)
      end
    end

    # 修改.podspec文件
    def modify_podspec_file
      # 1、移除.xcframework行和多余的空格
      pattern = ".xcframework"
      lines = File.readlines(@spec_path).reject { |line| line.match(pattern) }.filter { |element| element.strip.size > 0 }
      new_vendored_framework = get_vendored_frameworks
      # 插入新的vendored_frameworks
      lines.insert(lines.size - 1, new_vendored_framework)
      # 写入新的内容
      File.open(@spec_path, "w") { |file| file.puts lines }
    end

    # 生成vendored_framewoks的字符串
    def get_vendored_frameworks
      xc_files = Dir.glob(File.join(@framework_localPath, "*.xcframework")).map do |file|
        File.basename(file)
      end
      vendored_frameworks = "  s.vendored_frameworks = "
      xc_files.each do |line|
        vendored_frameworks = vendored_frameworks + "'" + line + "'" + "," + "\n" + "                          "
      end
      # 去掉末尾所有空格和最后的`,`
      vendored_frameworks.rstrip.chomp(",")
    end

    # 获取修改之前的versin
    def get_origin_version
      versin_line = File.readlines(@spec_path).filter { |line| line.gsub(/\s+/, "").match("s.version=") }
      raise "\u6CA1\u6709\u627E\u5230version" unless versin_line.any?

      version = versin_line.last.split("=").last

      # （/^\'|\'$/）去掉首尾单引号的正则
      version.strip.gsub(/^'|'$/, "")
    end

    # 生成新的version
    def gen_new_version(origin_version)
      # 按`·`分割一下
      version_split = origin_version.split(".")
      # 取出第一位日期部分
      first_part = version_split.first
      # 取出最后一位构建次数
      last_part = version_split.last
      # 获取当前日期
      current_date = Time.now.strftime("%Y%m%d")
      # 构建次数
      build_time = if first_part.eql?(current_date)
                     # 相等说明当前日期构建多次
                     last_part.to_i + 1
                   else
                     # 不相等说明隔天首次构建
                     0
                   end
      # 获取pubspec.yaml 中的版本号
      project_dir = Config.instance.project_dir
      yaml_path = if !project_dir
                    File.join(Dir.pwd, "pubspec.yaml")
                  else
                    File.join(project_dir, "pubspec.yaml")
                  end
      file_content = File.read(yaml_path)
      # 提取版本号
      version = file_content.match(/version: (.+)/)&.captures&.first
      # 最终新的version
      new_version = "#{current_date}.#{version}.#{build_time}"
      # 输出版本信息
      Flutter::Print.print_version_info(new_version, origin_version)
      new_version
    end

    # 更新版本
    def update_version(version)
      # 读取文件内容
      file_content = File.read(@spec_path)

      # 提取版本号
      version_match = file_content.match(/s\.version\s+=\s+'(.+)'/)
      current_version = version_match&.captures&.first

      return unless current_version

      # 替换版本号
      new_file_content = file_content.gsub(/s\.version\s+=\s+'#{current_version}'/, "s.version          = '#{version}'")

      # 将替换后的内容写回文件
      File.write(@spec_path, new_file_content)
    end

    # 推到远程
    def push_to_remote(version)
      log_products_diff
      # 当前的分支
      branch_name = `git branch --show-current`
      # 生成提交日志（版本号+构件类型+分支名）
      log = "版本号：#{version}---构件类型：#{@product_type.capitalize}---分支名：#{branch_name}"
      # 提交
      `git -C #{@framework_localPath} add -A`
      `git -C #{@framework_localPath} commit -m #{log}`
      `git -C #{@framework_localPath} push origin`
      # 打tag
      `git -C #{@framework_localPath} tag -a #{version} -m #{log}`
      `git -C #{@framework_localPath} push origin #{version}`

      # 切换到SoHuHost目录下执行`pod repo push`
      Dir.chdir(@framework_localPath) if @framework_localPath
      # podspec 推到远程
      result = system("pod repo push #{@spec_name} #{@podspec_name} --sources='#{@spec_url}' --allow-warnings --skip-import-validation")

      raise "上传失败。。。。。。" unless result

      print TTY::Box.success("#{@podspec_name}推送成功，请在项目中使用：\nflutter_pod '#{@sohu_host_project_name}', '#{version}'")
    end
  end
end
