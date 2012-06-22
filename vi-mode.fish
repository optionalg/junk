function direction_command
	# Embedded python... If you can do this in pure shell then more power to you :)
	set ret (python -c "

import sys
command = sys.argv[1]
direction = sys.argv[2]
new_pos = pos = int(sys.argv[3])
cmdline = '\n'.join(sys.argv[4:])

def dir_W():
	new_pos = cmdline.find(' ', pos + 1)
	if new_pos < 0:
		new_pos = len(cmdline)
	return new_pos + 1

def dir_E():
	new_pos = cmdline.find(' ', pos + 3)
	if new_pos < 0:
		new_pos = len(cmdline)
	return new_pos - 1

def dir_B():
	if pos == 0:
		return 0
	new_pos = cmdline.rfind(' ', 0, pos-1) + 1
	if new_pos < 0:
		new_pos = 0
	return new_pos

def dir(d): return globals()['dir_%s' % d]()

new_pos = dir(direction)

print cmdline
print new_pos

" $argv[1] $argv[2] (commandline -C) (commandline)) # commandline should always be last

	set new_pos $ret[-1]
	set -e ret[-1] # Guessing that deleting last element is likely to be faster than deleting first
	commandline $ret
	commandline -C $new_pos
end

function vi_mode_common -d "common key bindings for all vi-like modes"
	bind \e vi_mode_normal
	bind \cc 'echo; commandline ""; vi_mode_insert' # Breaks if multiline commandline
	bind \cd delete-or-exit
	bind \cl 'clear; commandline -f repaint'
end

function vi_mode_common_insert -d "common key bindings for all insert vi-like modes"
	vi_mode_common
	bind \e 'commandline -f backward-char; vi_mode_normal'
end

function bind_all
	# There seems to be some magic that doesn't work properly without this:
	bind '' self-insert

	python -c "
command = '''$argv'''
for c in map(chr, range(0x20, 0x7f)):
	q = '\"'
	if c == '\"':
		l = r = r'\\%s' % c
		q = '\''
	elif c in ['(', ')', '<', '>', ';', '|', '\'']:
		l = r = r'\%s' % c
	elif c == '\\\\':
		l = r'\\\\'
		r = r'\\\\\\\\'
	elif c == '\$':
		l = '\%s' % c
		r = r\"'\%s'\" % c
	else:
		l = r = \"'%s'\" % c
	print '''bind %s %s%s%s''' % (l, q, command.replace('%k', r), q)
" | .
end

function vi_mode
	set -g vi_mode $argv
	commandline -f repaint
end

function replace
	vi_mode 'r'
	bind --erase --all
	vi_mode_common

	# backward-char should happen last, but only works if specified first
	# (guess I should dig through the C code and figure out what is going
	# on):
	# bind_all "commandline -f delete-char; commandline -i %k; commandline -f backward-char; vi_mode_normal"
	bind_all "commandline -f backward-char delete-char; commandline -i %k; vi_mode_normal"

end

function overwrite
	vi_mode 'R'
	bind --erase --all
	vi_mode_common_insert

	bind_all "commandline -f delete-char; commandline -i %k"
end

function vi_mode_normal -d "WIP vi-like key bindings for fish (normal mode)"
	vi_mode ' '

	bind --erase --all

	# NOTE: bind '' self-insert seems to be required to allow the
	# prompt to change, but we don't want unbound keys to be able to
	# self-insert, so set the default binding, but bind everything to
	# do nothing (which is wasteful, but seems to work):
	bind_all ''

	vi_mode_common

	bind \n "commandline -f execute; vi_mode_insert"

	bind i vi_mode_insert
	bind I 'commandline -f beginning-of-line; vi_mode_insert'
	bind a 'commandline -f forward-char; vi_mode_insert'
	bind A 'commandline -f end-of-line; vi_mode_insert'

	bind j history-search-forward
	bind k history-search-backward

	bind h backward-char
	bind l forward-char
	bind b backward-word # Note: this implementation is buggy. Try using b from the end of 'echo hi' to see what I mean
	bind B 'direction_command "" B'
	bind w forward-word # FIXME: Should be start of next word
	bind W 'direction_command "" W'
	bind e forward-word # FIXME: Should be end of next word
	bind E 'direction_command "" E'
	bind 0 beginning-of-line
	bind _ beginning-of-line
	bind \$ end-of-line

	bind x delete-char
	bind D kill-line
	# bind Y 'commandline -f kill-whole-line yank'
	bind P yank
	bind p 'commandline -f yank forward-char' # Yes, this is reversed. Otherwise it does the wrong thing. Go figure.
	bind C 'commandline -f kill-line; vi_mode_insert'
	bind S 'commandline -f kill-whole-line; vi_mode_insert'
	bind s 'commandline -f delete-char; vi_mode_insert'
	bind r replace
	bind R overwrite

	# NOT IMPLEMENTED:
	# bind 2 vi-arg-digit
	# bind d delete-direction
	# bind c change-direction
	# bind y yank-direction
	# bind g magic :-P
	# bind u undo
	# bind f find
	# bind F find-prev
	# bind t till
	# bind T till-prev
	# bind o insert on new line below
	# bind O insert on new line above
	# bind ^a increment next number
	# bind ^a increment next number
	# bind /?nN search (jk kind of does this)
	# registers (maybe try to make sensible integration into X, like an
	#   explicit yank with y goes to an X selection, while an implicit
	#   delete with x etc. doesn't. "* and "+ should natually go to the
	#   appropriate X selection if possible)
	# etc.
end

function vi_mode_insert -d "vi-like key bindings for fish (insert mode)"
	vi_mode 'I'

	fish_default_key_bindings

	vi_mode_common_insert
end
