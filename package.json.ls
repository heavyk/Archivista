# Archivista!

name: 'archivista'
version: '0.1.2'
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
	walkdir: \x # get rid of this... use fstreams
	archiver: \x
	debug: \x
runtimeDependencies:
	request: \x
	#fstream: \x
	#'fstream-ignore': \x
	tar: \x
	#temp: \x
	rimraf: \x
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
