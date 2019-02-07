'use strict'

/* global Ipfs */
/* eslint-env browser */

const repoPath = `ipfs-${Math.random()}`
const ipfs = new Ipfs({ repo: repoPath })

ipfs.on('ready', () => {
    console.log("IPFS ready");
    _postMessage({ method: 'loaded' });
});

function uploadBlob(id, blobBase64) {
    const blob = ipfs.types.Buffer.from(blobBase64, 'base64');
    ipfs.add(blob, (error, response) => {
      _postMessage({ id, method: 'uploadBlob', response, error: error && error.toString() });
    });
}

// NOTE: Avoid clashing with window.postMessage
function _postMessage(message) {
  webkit.messageHandlers.callback.postMessage(message);
}


