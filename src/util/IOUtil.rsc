module util::IOUtil

import lang::java::\syntax::Java18;
import IO;

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