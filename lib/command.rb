require "claide"

module Flutter
  class Command < CLAide::Command
    self.abstract_command = true
    self.command = "flutter-cli"
    # self.version = Flutter::Deploy::VERSION
    self.summary = 'Build the Flutter module into a framework and upload it to your private repository'
    self.description = "flutter-deploy, build and deploy to private git repo"
  end
end
