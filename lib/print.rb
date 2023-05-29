require "tty-box"

module Flutter
  class Print
    def self.print_product_info(product_type, number, path)
      print TTY::Box.info "产物类型：#{product_type}\n产物数量：#{number}\n产物路径：#{path}"
    end

    def self.print_all_products(products)
      print TTY::Box.info "产物：\n#{products}"
    end

    def self.print_version_info(new_version, old_version)
      print TTY::Box.info "新版本号为：#{new_version}\n旧版本号为：#{old_version}\n''"
    end
  end
end
