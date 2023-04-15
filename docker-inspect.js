#!/usr/bin/env node
const program = require('commander');
const child_process = require('child_process');

program
  .arguments('image')
  .parse(process.argv);

let images;
images = child_process.execSync(`docker images -q`).toString().trim().split('\n');
images = images.slice(0, 5);

images.forEach((image) => {
  let result = child_process.execSync(`docker inspect ${image}`).toString();
  JSON.parse(result).forEach((elem) => {
    console.log([image, elem.RepoTags[0], formatDate(elem.Created), humanReadable(elem.Size)].join('\t'));
  });
});

function formatDate(str) {
  date = new Date(str);
  return date.toISOString().split('T')[0] + ' ' + date.toTimeString().split(' ')[0];
}

function humanReadable(size) {
  const k = 1000;

  let kilo = 0;
  if (size > k) {
    kilo = Math.floor(size / k);
    size = size % k;
  }
  let mega = 0;
  if (kilo > k) {
    mega = Math.floor(kilo / k);
    kilo = kilo % k;
  }

  let out = [];
  if (mega) {
    out.push(mega, 'MB');
  }
  if (kilo) {
    out.push(kilo, 'KB');
  }
  if (size) {
    out.push(size, 'B');
  }
  
  return out.join(' ');
}

function formatSize(size) {
  const k = 1000;
  
  let unit = "";
  if (size > k) {
    size /= k;
    unit = "KB";
  }
  if (size > k) {
    size /= k;
    unit = "MB";
  }
  
  if (unit) {
    return `${size.toFixed(2)} ${unit}`;
  } else {
    return size;
  }
}
