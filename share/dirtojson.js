#!/usr/bin/env node
'use strict';

var fs = require('fs');
var path = require('path');


/**
 * Recursively calls {@link fs.readdirSync}.
 *
 * For example, where {@link fs.readdirSync} returns:
 *   ['Desktop', '.vimrc', ...]
 * for with an argument of $HOME, this function returns:
 *   [{Desktop: ['About.pdf'], '.vimrc', ...]
 *
 * @param {string} dirToList
 * @return {!Array.<string|!Object>}
 *     {@link fs.readdirSync} response, where file names which are directories
 *     are replaced by an Object with a single property of the same name,
 *     pointing to an Array as usual.
 */
var listFiles = module.exports = function(dirToList) {
  if (!fs.statSync(dirToList).isDirectory()) {
    throw new Error('argument must be a directory');
  }

  var listing = fs.readdirSync(dirToList);
  listing.forEach(function(fileName, idx) {
    var file = path.resolve(dirToList, fileName);
    if (fs.statSync(file).isDirectory()) {
      listing[idx] = {};
      listing[idx][fileName] = listFiles(file);
    }
  });
  return listing;
};


if (require.main === module) {
  console.log(
      JSON.stringify(
          module.exports(
              path.resolve(
                  process.argv[2]))));
}
