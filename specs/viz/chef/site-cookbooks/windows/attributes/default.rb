default['vim']['home']     = "#{ENV['USERPROFILE']}\\bin\\vim"

#if kernel['machine'] =~ /x86_64/
#     default['vim']['url']                    = "https://dforest.watch.impress.co.jp/library/v/vim/11702/gvim82.exe"
#     default['vim']['version']               = "#{ENV['USERPROFILE']}\\bin\\vim\\vim82"
#else
#     default['vim']['url']                    = "http://vim-win3264.googlecode.com/files/vim72-376.zip"
#     default['vim']['version']               = "#{ENV['USERPROFILE']}\\bin\\vim\\vim72"
#end
#
default['vim']['url']                   = "https://dforest.watch.impress.co.jp/library/v/vim/11702/gvim82.exe"
default['vim']['version']               = "#{ENV['USERPROFILE']}\\bin\\vim\\vim82"

# VMD install
