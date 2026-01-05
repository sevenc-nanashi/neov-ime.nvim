# frozen_string_literal: true

task :update_neovim do
  if Dir.exist?("./external/neovim")
    Dir.chdir("./external/neovim") do
      sh "git pull"
    end
  else
    sh "git clone https://github.com/neovim/neovim.git ./external/neovim --depth 1"
  end
end
