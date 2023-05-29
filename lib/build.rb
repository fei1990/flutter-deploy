require "command"
require "produce"
require "repo"
require "upload"
require "colored2"

module Flutter
  class Command
    class Build < Command
      self.summary = "Build the Flutter module into a framework and upload it to your private repository"
      self.description = <<-DESC
        Build the Flutter module into a framework and upload it to your private repository. If an `BUILD_CONFIG` is specified, the command can produce a given configuration framework.
        You can set up the configuration for `debug`、`profile`、`release`, If none given, By default, all build configurations are built.
      DESC
      self.arguments = [
        CLAide::Argument.new("BUILD_CONFIG", false, false)
      ]
      def self.options
        [
          ["--build-only", "build only Don\u2019t deploy"],
          ["--ignore-gp", "Don\u2019t pull new code from remote, use your local code"],
          ["--messae=msg", "git commit log"],
          ["--branch=branch", "which branch to build"],
          ["--project-dir=/project/dir", "The path to the root of the project directory"]
        ].concat(super)
      end

      def initialize(argv)
        super
        @build_only = argv.flag?("build-only")
        Flutter::Config.instance.ignore_gp = argv.flag?("ignore-gp")
        Flutter::Config.instance.debug = argv.flag?("debug")
        # flutter module 根目录
        Flutter::Config.instance.project_dir = argv.option("project-dir")
        Flutter::Config.instance.config = argv.shift_argument
      end

      def validate!
        super
        build_type = Config.instance.config
        return unless !build_type.nil? && !Flutter::Config.instance.product_types.include?(build_type)

        help! "构建类型指定错误，请输入要构建包的类型：（debug/profile/release）".red
      end

      def run
        # 尝试更新私有库
        Repo.repo_update
        produce = Flutter::Produce.new
        # 构建前的初始化工作
        produce.setup
        # 开始构建
        result = produce.build
        # 上传到私服
        raise "构建失败，请检查环境配置......".red unless result

        # 输出产物信息
        produce.log
        return if @build_only

        # 上传
        deploy = Flutter::Upload.new
        deploy.upload
      end
    end
  end
end
