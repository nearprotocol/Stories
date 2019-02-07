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

const config = {
    baseUrl: 'https://studio.nearprotocol.com/contract-api',
    nodeUrl: 'https://studio.nearprotocol.com/devnet',
    contractName: 'studio-wv52jrdjn'
};
Cookies.set('fiddleConfig', config);

async function initNear() {
    const near = await nearlib.dev.connect();
    const nearUserId = nearlib.dev.myAccountId;
    return near.loadContract(config.contractName, {
        // NOTE: This configuration only needed while NEAR is still in development
        viewMethods: ["getLastVideos"],
        changeMethods: ["postVideo"],
        sender: nearUserId
    });
}
const initNearPromise = initNear();

function postVideo(id, hash) {
    initNearPromise.then(contract => {
        contract.postVideo({ hash }).then(() => {
            _postMessage({ id, method: 'postVideo' });
        }, (error) => {
            _postMessage({ id, method: 'postVideo', error: error && error.toString() });
        })
    });
}

