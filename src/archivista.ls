Fs = require 'fs'
Path = require 'path'
walkdir = require 'walkdir'
archiver = require 'archiver'
Debug = require \debug
debug = Debug 'Archivist'


Zip = (config) ->
  instance = this
  throw 'You need to specify the zip output file.' if not config.file
  zip = archiver.createZip {
    level: 1
    config.comment
  }
  zip.pipe Fs.createWriteStream config.file
  instance.zip = zip
  instance.config = config
  return instance

Zip::add = (paths, opt_callback, opt_basepath) ->
  instance = this
  if typeof paths is 'string'
    if not Fs.existsSync paths
      debug 'File %s not found.', paths
      return
    statSync = Fs.statSync paths
    if statSync.isFile!
      paths = [paths]
    else if statSync.isDirectory!
      opt_basepath = paths
      paths = walkdir.sync paths
  config = instance.config
  filepath = paths.pop!
  relative = void
  if filepath
    # '../' * (opts.strip or 0)
    relative = Path.join config.root, opt_basepath, '../' * (config.strip or 0), Path.relative opt_basepath, filepath
    Fs.stat filepath, (err, stat) ->
      if not stat
        debug 'File %s not found.', filepath
        instance.add paths, opt_callback, opt_basepath
      else
        if stat.isFile!
          debug 'Added %s', relative
          instance.zip.addFile (Fs.createReadStream filepath), {name: relative}, -> instance.add paths, opt_callback, opt_basepath
        else
          instance.add paths, opt_callback, opt_basepath
  else
    opt_callback.call instance, paths if opt_callback

Zip::done = (opt_callback) ->
  instance = this
  config = instance.config
  zip = instance.zip
  zip.finalize ((err) -> opt_callback.call instance if opt_callback)

export Zip = Zip
