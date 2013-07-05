var Fs, Path, walkdir, archiver, Debug, debug, Rimraf, Tar, Request, Zlib, dl_and_untar, Zip, out$ = typeof exports != 'undefined' && exports || this;
Fs = require('fs');
Path = require('path');
walkdir = require('walkdir');
archiver = require('archiver');
Debug = require('debug');
debug = Debug('Archivist');
out$.dl_and_untar = dl_and_untar = function(opts, tar_done){
  var url, local_file, tar;
  if (!Rimraf) {
    Rimraf = require('rimraf');
  }
  if (!Tar) {
    Tar = require('tar');
  }
  if (!Request) {
    Request = require('request');
  }
  if (!Zlib) {
    Zlib = require('zlib');
  }
  url = opts.url || '';
  local_file = opts.file;
  tar = new Tar.Extract(opts);
  tar.on('error', tar_done);
  tar.on('end', tar_done);
  tar.on('entry', function(entry){});
  Fs.exists(local_file, function(existing){
    var sha1, dl, bytes, bytes_total, last_percent, lo;
    console.log("existing", existing, local_file);
    if (opts.sha1) {
      sha1 = require('crypto').createHash('sha1');
    }
    if (existing) {
      dl = Fs.createReadStream(local_file);
      dl.on('error', tar_done);
      dl.on('open', function(fd){
        var st;
        return st = Fs.fstatSync(fd);
      });
      dl.on('data', function(d){
        if (sha1) {
          return sha1.update(d);
        }
      });
      dl.on('end', function(){
        if (sha1 && opts.sha1 !== sha1.digest('hex')) {
          return tar_done("sha1 hash does not match " + opts.sha1);
        }
      });
      return dl.pipe(Zlib.createGunzip()).pipe(tar);
    } else if (!url) {
      return tar_done(new Error("local file '" + local_file + "' does not exist!"));
    } else {
      debug("Request.get %s", url);
      bytes = 0;
      bytes_total = -1;
      last_percent = 0;
      lo = Fs.createWriteStream(local_file + '.part');
      lo.on('error', tar_done);
      return lo.on('open', function(){
        var dl, ext;
        dl = Request.get(url);
        dl.on('response', function(res){
          if ((bytes_total = res.headers['content-length']) > 0) {
            return tar.emit('progress', {
              bytes: bytes,
              bytesTotal: bytes_total,
              percent: bytes / bytes_total
            });
          }
        });
        dl.on('end', function(){
          return Fs.rename(local_file + '.part', local_file, function(err){
            if (err) {
              tar_done(err);
            }
            return debug("renamed %s", local_file);
          });
        });
        dl.pipe(lo);
        switch (ext = url.substr(1 + url.lastIndexOf('.'))) {
        case 'tgz':
        case 'gz':
          dl.pipe(Zlib.createGunzip()).pipe(tar);
          break;
        case 'tbz':
        case 'bz':
          tar_done(new Error("bzip format not supported yet"));
          break;
        case 'txz':
        case 'xz':
          dl.pipe(require('xz-pipe').d()).pipe(tar);
          break;
        default:
          tar_done(new Error("unknown format '" + ext + "'"));
        }
        dl.on('open', function(fd){
          var st;
          return st = Fs.fstatSync(fd);
        });
        dl.on('data', function(d){
          var percent;
          if (sha1) {
            sha1.update(d);
          }
          if (bytes_total > 0) {
            bytes = bytes + d.length;
            if (last_percent !== (percent = Math.round(bytes / bytes_total * 100))) {
              last_percent = percent;
              return tar.emit('progress', {
                bytes: bytes,
                bytesTotal: bytes_total,
                percent: percent
              });
            }
          }
        });
        dl.on('error', tar_done);
        return dl.on('end', function(){
          if (sha1 && opts.sha1 !== sha1.digest('hex')) {
            return tar_done("sha1 hash does not match " + opts.sha1);
          }
        });
      });
    }
  });
  return tar;
};
Zip = function(config){
  var instance, zip;
  instance = this;
  if (!config.file) {
    throw 'You need to specify the zip output file.';
  }
  zip = archiver.createZip({
    level: 1,
    comment: config.comment
  });
  zip.pipe(Fs.createWriteStream(config.file));
  instance.zip = zip;
  instance.config = config;
  return instance;
};
Zip.prototype.add = function(paths, opt_callback, opt_basepath){
  var instance, config, filepath, do_add;
  instance = this;
  config = instance.config;
  filepath = paths.pop();
  do_add = function(){
    var relative;
    if (filepath) {
      relative = Path.join(config.root, opt_basepath, repeatString$('../', config.strip || 0), Path.relative(opt_basepath, filepath));
      return Fs.stat(filepath, function(err, stat){
        if (!stat) {
          debug('File %s not found.', filepath);
          return instance.add(paths, opt_callback, opt_basepath);
        } else {
          if (stat.isFile()) {
            debug('Added %s', relative);
            return instance.zip.addFile(Fs.createReadStream(filepath), {
              name: relative
            }, function(){
              return instance.add(paths, opt_callback, opt_basepath);
            });
          } else {
            return instance.add(paths, opt_callback, opt_basepath);
          }
        }
      });
    } else {
      if (opt_callback) {
        return opt_callback.call(instance, paths);
      }
    }
  };
  if (typeof paths === 'string') {
    return Fs.exists(paths, function(exists){
      if (!exists) {
        debug('File %s not found.', paths);
        return opt_callback(new Error("File " + paths + " not found."));
      } else {
        return Fs.stat(paths, function(st){
          if (st.isFile()) {
            paths = [paths];
            return do_add();
          } else if (st.isDirectory()) {
            opt_basepath = paths;
            return walkdir(paths, function(p){
              paths = p;
              return do_add();
            });
          } else {
            return do_add();
          }
        });
      }
    });
  } else {
    return do_add();
  }
};
Zip.prototype.done = function(opt_callback){
  var instance, config, zip;
  instance = this;
  config = instance.config;
  zip = instance.zip;
  return zip.finalize(function(err){
    if (opt_callback) {
      return opt_callback.call(instance);
    }
  });
};
out$.Zip = Zip = Zip;
function repeatString$(str, n){
  for (var r = ''; n > 0; (n >>= 1) && (str += str)) if (n & 1) r += str;
  return r;
}