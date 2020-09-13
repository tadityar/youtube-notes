const path = require('path')
const fs = require('fs')

const srcFiles = ['public/index.html', 'public/view.html']

srcFiles.forEach((srcFile, i) => {
  const srcContent = fs.readFileSync(srcFile, { encoding: 'utf8' })
  const newContent = srcContent.replace('{HASURA_GRAPHQL_ENDPOINT}', process.env.HASURA_GRAPHQL_ENDPOINT)
  fs.writeFile(srcFile, newContent, 'utf8', function (err) {
     if (err) return console.log(err);
  });
});
