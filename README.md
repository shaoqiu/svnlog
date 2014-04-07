svn-log
=======

use vim to show svn log,and diff

install
==========

use vimdiff to replace svn diff default
modify your svn diff command like this:
edit /usr/local/bin/svndiff and input these line

	FF="vimdiff"
	# SVN diff命令会传入两个文件的参数 
	LEFT=${6}
	RIGHT=${7}
	# 拼接成diff命令所需要的命令格式
	$DIFF $LEFT $RIGHT

save the file and chmod a+x 
and then modify ~/.subversion/config,
change line 

	# diff-cmd = diff_program (diff, gdiff, etc.)
	
to 

	diff-cmd = /usr/local/bin/svndiff
	

add a line into your .vimrc:

	Bundle 'konkashaoqiu/svnlog.git'
	Bundle 'konkashaoqiu/vim-tools.git'

the vim-tools include some functions that I use a lot

useage
==========

cd to the svn dir 
open vim
type: 

	:SVNLog [path]

path is the dir or file which you want to show log,
default is current dir.
then it will create a new tab,it contains three window
the top window is the commit comments,
the middle window is the log list,
the bottom window is change path.
if you want to show differ, move focus to the change path window
and type 'Enter', it will call svn diff to show the diff between current version and pre version of the file in the cusor

note
==========


