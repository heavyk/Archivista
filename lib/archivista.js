var Fs, Path, walkdir, archiver, Debug, debug, Zip, out$ = typeof exports != 'undefined' && exports || this;
Fs = require('fs');
Path = require('path');
walkdir = require('walkdir');
archiver = require('archiver');
Debug = require('debug');
debug = Debug('Archivist');
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
  var instance, statSync, config, filepath, relative;
  instance = this;
  if (typeof paths === 'string') {
    if (!Fs.existsSync(paths)) {
      debug('File %s not found.', paths);
      return;
    }
    statSync = Fs.statSync(paths);
    if (statSync.isFile()) {
      paths = [paths];
    } else if (statSync.isDirectory()) {
      opt_basepath = paths;
      paths = walkdir.sync(paths);
    }
  }
  config = instance.config;
  filepath = paths.pop();
  relative = void 8;
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