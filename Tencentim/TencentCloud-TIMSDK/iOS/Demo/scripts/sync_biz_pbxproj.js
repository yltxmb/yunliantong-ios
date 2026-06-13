/**
 * Sync all TUIKitDemo/Biz/*.h and *.m into project.pbxproj
 * Usage: node scripts/sync_biz_pbxproj.js
 */
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const bizDir = path.join(root, 'TUIKitDemo', 'Biz');
const pbxPath = path.join(root, 'TUIKitDemo.xcodeproj', 'project.pbxproj');

const files = fs.readdirSync(bizDir).filter((f) => f.endsWith('.h') || f.endsWith('.m')).sort();
const mFiles = files.filter((f) => f.endsWith('.m'));
if (mFiles.length === 0) {
  console.error('No Biz .m files found');
  process.exit(1);
}

let id = 29001;
const entries = [];
for (const file of files) {
  const fid = `YLTBIZ${String(id).padStart(6, '0')}`;
  id += 1;
  const isM = file.endsWith('.m');
  const bid = isM ? `YLTBLD${String(id - 1).padStart(6, '0')}` : null;
  entries.push({ file, fid, bid });
}

let content = fs.readFileSync(pbxPath, 'utf8');

// strip previous Biz registrations
content = content.replace(/\t\tYLTBIZ029[0-9]{3}[^\n]+\n/g, '');
content = content.replace(/\t\tYLTBLD029[0-9]{3}[^\n]+\n/g, '');
content = content.replace(/\t\t\t\tYLTBLD029[0-9]{3}[^\n]+\n/g, '');

const fileRefLines = entries.map(
  (e) =>
    `\t\t${e.fid} /* ${e.file} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = ${e.file}; sourceTree = "<group>"; };`
);
const buildLines = entries
  .filter((e) => e.bid)
  .map(
    (e) =>
      `\t\t${e.bid} /* ${e.file} in Sources */ = {isa = PBXBuildFile; fileRef = ${e.fid} /* ${e.file} */; };`
  );
const groupLines = entries.map((e) => `\t\t\t\t${e.fid} /* ${e.file} */,`);
const sourceLines = entries
  .filter((e) => e.bid)
  .map((e) => `\t\t\t\t${e.bid} /* ${e.file} in Sources */,`);

const anchorFileRef = '\t\t935F7C51293615770033D099 /* LoginController.m */';
if (!content.includes(anchorFileRef)) {
  console.error('Anchor for PBXFileReference not found');
  process.exit(1);
}
content = content.replace(
  anchorFileRef + ' = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.objc; path = LoginController.m; sourceTree = "<group>"; };',
  anchorFileRef +
    ' = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.objc; path = LoginController.m; sourceTree = "<group>"; };\n' +
    fileRefLines.join('\n')
);

const bfEnd = '/* End PBXBuildFile section */';
content = content.replace(bfEnd, buildLines.join('\n') + '\n' + bfEnd);

const groupRe =
  /YLTBIZGRP0000000000000001 \/\* Biz \*\/ = \{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = \(\n([\s\S]*?)\t\t\t\);\n\t\t\tpath = Biz;/;
if (!groupRe.test(content)) {
  console.error('Biz group not found');
  process.exit(1);
}
content = content.replace(
  groupRe,
  `YLTBIZGRP0000000000000001 /* Biz */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n${groupLines.join('\n')}\n\t\t\t);\n\t\t\tpath = Biz;`
);

const srcAnchor = '\t\t\t\t935F7C93293615770033D099 /* LoginController.m in Sources */,';
content = content.replace(srcAnchor, sourceLines.join('\n') + '\n' + srcAnchor);

fs.writeFileSync(pbxPath, content);

// verify
const verify = fs.readFileSync(pbxPath, 'utf8');
const refCount = (verify.match(/YLTBIZ029[0-9]{3} \/\* YLT.+ \*\/ = \{isa = PBXFileReference/g) || []).length;
const buildCount = (verify.match(/YLTBLD029[0-9]{3} \/\* YLT.+ in Sources \*\/ = \{isa = PBXBuildFile/g) || []).length;
const srcCount = (verify.match(/\t\t\t\tYLTBLD029[0-9]{3} \/\* YLT.+ in Sources \*\/,/g) || []).length;
console.log(`OK: ${mFiles.length} .m files | fileRefs=${refCount} buildFiles=${buildCount} sources=${srcCount}`);
if (refCount !== mFiles.length * 2 || buildCount !== mFiles.length || srcCount !== mFiles.length) {
  console.error('Verification failed');
  process.exit(1);
}
