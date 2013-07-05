Fs = require 'fs'
Path = require 'path'
walkdir = require 'walkdir'
archiver = require 'archiver'
Debug = require \debug
debug = Debug 'Archivist'

var Rimraf, Tar, Request, Zlib

export dl_and_untar = (opts, tar_done) ->
  unless Rimraf => Rimraf := require \rimraf
  unless Tar => Tar := require \tar
  unless Request => Request := require \request
  unless Zlib => Zlib := require \zlib

  url = opts.url or ''
  local_file = opts.file
  # if url
  #   Temp.mkdir "", (err, path) ->
  #     local_file = Path.join path, ???
  # else
  #   tar_done new Error "you must specify"
  #url = Url.parse url

  # INCOMPLETE: if this is a local file, detect it do not download
  # INCOMPLETE: also, download into a tmp folder if

  #ee = opts.progress
  #task = opts.task
  # XXX make this a task branch because we're returning when the readstream ends, and not when all files have been successfully written to disk
  #task = opts.task.branch "download & extract #{url}"
  # ^--- I think I want to show progress here...

  # INCOMPLETE: close the local file streams

  tar = new Tar.Extract opts
  tar.on \error, tar_done
  tar.on \end, tar_done
  tar.on \entry, (entry) ->
    #console.log "entry", entry.props.path
    #unless test entry
    # console.log "rejected!"
  Fs.exists local_file, (existing) ->
    console.log "existing", existing, local_file
    if opts.sha1
      sha1 = require \crypto .createHash \sha1
    if existing
      dl = Fs.createReadStream local_file
      dl.on \error, tar_done
      dl.on \open, (fd) ->
        st = Fs.fstatSync fd
      dl.on \data, (d) ->
        if sha1 then sha1.update d
      dl.on \end, ->
        if sha1 and opts.sha1 isnt sha1.digest \hex
          tar_done "sha1 hash does not match #{opts.sha1}"
      dl.pipe Zlib.createGunzip! .pipe tar
    else if not url
      tar_done new Error "local file '#{local_file}' does not exist!"
    else
      debug "Request.get %s", url
      bytes = 0
      bytes_total = -1
      last_percent = 0
      lo = Fs.createWriteStream local_file+'.part'
      lo.on \error, tar_done
      lo.on \open ->
        dl = Request.get url
        dl.on \response (res) ->
          if (bytes_total := res.headers.'content-length') > 0
            tar.emit \progress {
              bytes: bytes
              bytesTotal: bytes_total
              percent: bytes / bytes_total
            }
        dl.on \end -> # url.href
          Fs.rename local_file+'.part', local_file, (err) ->
            if err then tar_done err
            debug "renamed %s", local_file
        dl.pipe lo
        switch ext = url.substr 1+url.lastIndexOf '.'
        | 'tgz' 'gz' =>
          dl.pipe Zlib.createGunzip! .pipe tar
        | 'tbz' 'bz' =>
          tar_done new Error "bzip format not supported yet"
        | 'txz' 'xz' =>
          dl.pipe require('xz-pipe').d! .pipe tar
        | otherwise =>
          tar_done new Error "unknown format '#{ext}'"
        dl.on \open, (fd) ->
          # why the fuck is this here???
          st = Fs.fstatSync fd
        dl.on \data, (d) ->
          if sha1 then sha1.update d
          if bytes_total > 0
            bytes := bytes + d.length
            #console.log ":: ", bytes, percent
            if last_percent isnt percent = Math.round bytes / bytes_total * 100
              last_percent := percent
              tar.emit \progress {
                bytes: bytes
                bytesTotal: bytes_total
                percent: percent
              }
        dl.on \error, tar_done
        #dl.on \data, (data) ->
        # lo.write data
        dl.on \end, ->
          if sha1 and opts.sha1 isnt sha1.digest \hex
            tar_done "sha1 hash does not match #{opts.sha1}"
  return tar

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
  config = instance.config
  filepath = paths.pop!
  do_add = ->
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
  if typeof paths is 'string'
    (exists) <- Fs.exists paths
    if not exists
      debug 'File %s not found.', paths
      opt_callback new Error "File #{paths} not found."
    else
      (st) <- Fs.stat paths
      if st.isFile!
        paths := [paths]
        do_add!
      else if st.isDirectory!
        opt_basepath := paths
        walkdir paths, (p) ->
          paths := p
          do_add!
      else do_add!
  else do_add!


Zip::done = (opt_callback) ->
  instance = this
  config = instance.config
  zip = instance.zip
  zip.finalize ((err) -> opt_callback.call instance if opt_callback)

export Zip = Zip
