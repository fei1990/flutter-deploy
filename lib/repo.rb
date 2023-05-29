module Flutter
  class Repo
    def self.repo_update
      spec_path1 = File.expand_path("~/.cocoapods/repos/ios_sohu_spec/")
      spec_path2 = File.expand_path("~/.cocoapods/repos/SHSpecs/")
      p = Pathname.new(spec_path1)
      if Dir.exist?(p.realpath)
        `pod repo update ~/.cocoapods/repos/ios_sohu_spec/`
      else
        `pod repo add ios_sohu_spec git@code.sohuno.com:mtpc_sh_ios/ios_sohu_spec.git`
      end

      if File.exist?(spec_path2)
        `pod repo update ~/.cocoapods/repos/SHSpecs/`
      else
        `pod repo add SHSpecs git@code.sohuno.com:MPTC-iOS/SHSpecs.git`
      end
    end
  end
end
