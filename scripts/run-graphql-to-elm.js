const { graphqlToElm } = require('graphql-to-elm')
const glob = require('glob')
const path = require('path')
const fs = require('fs')
const mkdirp = require('mkdirp')

// pre-process graphql files
const srcPath = 'src'
const buildPath = 'build'
// const fragmentSuffix = '.fragment.gql'
// const fragments = {}
// mkdirp.sync(buildPath)
// // 1. build a dictionary of fragmentName -> fragmentContent from *.fragment.gql
// glob.sync(srcPath + '/Portal2API/*' + fragmentSuffix).forEach((srcFile, i) => {
//   const fragmentName = path.basename(srcFile).replace(fragmentSuffix, '')
//   fragments[fragmentName] = fs.readFileSync(srcFile, { encoding: 'utf8' })
// })
// 2. for each *.graphql
//    a. copy into buildPath
//    b. for each fragmentName found used in graphql file, append fragmentContent
glob.sync(srcPath + '/db/*.graphql').forEach((srcFile, i) => {
  const buildFile = path.join(buildPath, srcFile.substring(srcPath.length))
  mkdirp.sync(path.dirname(buildFile))
  const srcContent = fs.readFileSync(srcFile, { encoding: 'utf8' })
  // const appendices = []
  // for (const fragmentName in fragments) {
  //   if (srcContent.indexOf('...' + fragmentName + '\n') !== -1) {
  //     appendices.push(fragments[fragmentName])
  //   }
  // }
  fs.writeFileSync(buildFile, srcContent, { encoding: 'utf8' })

  // using explicit index count loop because we're dynamically growing `appendices` inside the loop
  // for (let i = 0; appendices[i]; i++) {
  //   const fragmentContent = appendices[i]
  //   for (const fragmentName in fragments) {
  //     if (fragmentContent.indexOf('...' + fragmentName + '\n') !== -1) {
  //       // what if fragment contains fragments, add on!
  //       if (appendices.indexOf(fragments[fragmentName]) === -1) {
  //         // but only if it's not already added
  //         appendices.push(fragments[fragmentName])
  //       }
  //     }
  //   }
  //   fs.appendFileSync(buildFile, '\n\n' + fragmentContent, { encoding: 'utf8' })
  // }
})

// generate elm from graphql files
const queries = glob.sync(buildPath + '/db/*.graphql')
graphqlToElm({
  schema: './schema.graphql',
  queries: queries,
  src: buildPath,
  dest: srcPath,
  scalarEncoders: {
    uuid: { type: 'Ext.Json.UUID.UUID', encoder: 'Ext.Json.Encoder.encodeUUID' },
    jsonb: { type: 'Ext.Json.JsonB.JsonB', encoder: 'Ext.Json.Encoder.encodeJsonB' }
  },
  scalarDecoders: {
    uuid: { type: 'Ext.Json.UUID.UUID', decoder: 'Ext.Json.Decoder.decodeUUID' },
    jsonb: { type: 'Ext.Json.JsonB.JsonB', decoder: 'Ext.Json.Decoder.decodeJsonB' },
  }
})
