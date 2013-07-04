# Archivista!

name: 'Archivista'
version: '0.1.0'
description: 'gatta have the right tools for the right job, ya know?'
keywords: [
	'update'
]
homepage: 'https://github.com/heavyk/Archivista'
author: 'Kenneth Bentley <mechanicofthesequence@gmail.com>'
contributors: [
	'Kenneth Bentley <mechanicofthesequence@gmail.com>'
]
maintainers: [
	'Kenneth Bentley <mechanicofthesequence@gmail.com>'
]
engines:
	node: '>0.8.3'
repository:
	type: 'git'
	url: 'https://github.com/heavyk/Archivista.git'
bugs:
	url: 'https://github.com/heavyk/Archivista/issues'
main: './lib/archivista.js'
dependencies:
	semver: \x
	#request: \x
	walkdir: \x # get rid of this... use fstreams
	#fstream: \x
	#'fstream-ignore': \x
	#tar: \x
	archiver: \x
	#temp: \x
	#rimraf: \x
	debug: \x
	#lodash: \x
	#mkdirp: \x
directories:
	src: 'src'
	lib: 'lib'
	#doc: 'doc'
	example: 'examples'
sencillo:
	universe: \facilmente
	creator:
		name: 'heavyk'
		email: 'mechanicofthesequence@gmail.com'
#updater:
#	manifest: ...
#	repository:
#		type: \git
#		url: 'git://github.com/heavyk/Archivista.git'
