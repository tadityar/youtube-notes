const { graphqlToElm } = require('graphql-to-elm')
const glob = require('glob')
const path = require('path')
const fs = require('fs')
const mkdirp = require('mkdirp')

// pre-process graphql files
const srcPath = 'src'
const buildPath = 'build'

// for each *.graphql, copy into buildPath
glob.sync(srcPath + '/Db/*.graphql').forEach((srcFile, i) => {
  const buildFile = path.join(buildPath, srcFile.substring(srcPath.length))
  mkdirp.sync(path.dirname(buildFile))
  const srcContent = fs.readFileSync(srcFile, { encoding: 'utf8' })
  fs.writeFileSync(buildFile, srcContent, { encoding: 'utf8' })
  console.log("copied", srcFile, "to", buildFile)
})

// generate elm from graphql files
const queries = glob.sync(buildPath + '/Db/*.graphql')
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
