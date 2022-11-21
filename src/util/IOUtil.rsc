module util::IOUtil

import IO;
import String;

/**
 * List all files from an original location. 
 */
list[loc] findAllFiles(loc location, str ext) {
  res = [];
  list[loc] allFiles = []; 
  
  if(isDirectory(location)) {
     allFiles = location.ls;
  }
  else {
    allFiles = [location];
  }
  
  for(loc l <- allFiles) {
    if(isDirectory(l)) {
      res = res + (findAllFiles(l, ext));
    }
    else {
      if(l.extension == ext) {
         res = l + res;
      };
    };
  };
  return res; 
}

/**
 * List all Java test files from an original location. 
 */
list[loc] findAllTestFiles(loc location, str ext, bool isTestFolder) {
  res = [];
  list[loc] allFiles = []; 
  
  bool isSrcFolder = false;

  if(isDirectory(location)) {
    if (endsWith(location.path, ".git")) {
      return [];
    }

    if (endsWith(location.path, "/src")) {
      isSrcFolder = true;
    }

    allFiles = location.ls;
  }
  else {
    allFiles = [location];
  }

  if (isSrcFolder) {
    for(loc l <- allFiles) {
      if(isDirectory(l) && endsWith(l.path, "/src/test")) {
        res = res + (findAllTestFiles(l, ext, true));
      }
    };
  } else {
    for(loc l <- allFiles) {
      if(isDirectory(l)) {
        res = res + (findAllTestFiles(l, ext, isTestFolder));
      }
      else {
        if(l.extension == ext && isTestFolder) {
          res = l + res;
        };
      };
    };
  }
  return res; 
}