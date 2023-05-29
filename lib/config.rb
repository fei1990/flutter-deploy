module Flutter
  class Config
    # 声明私有方法
    private_class_method :new

    attr_reader :router_name, :swift_version, :source, :xcconfig_path, :podfile_path, :framework_path, :product_types

    attr_accessor :project_dir, :config, :debug, :new_products, :ignore_gp

    def self.instance
      @instance ||= new
    end

    def initialize
      @source = "source 'git@code.sohuno.com:mtpc_sh_ios/ios_sohu_spec.git'"
      @router_name = "  pod 'SHNRouter', :subspecs => ['Core','Flutter'], :source => 'git@code.sohuno.com:mtpc_sh_ios/ios_sohu_spec.git'"
      @swift_version = "SWIFT_VERSION=4.0"
      @xcconfig_path = ".ios/Flutter/Generated.xcconfig"
      @podfile_path = ".ios/Podfile"
      @framework_path = "./build/flutter"
      @product_types = %w[debug profile release]
    end
  end
end
