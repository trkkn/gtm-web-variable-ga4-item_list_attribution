___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "TRKKN - GA4 item_list_attribution",
  "description": "Persists available item list information (item_list_id, item_list_name, index) or creates item_list_name from a capturing ecommerce event along the purchase funnel for easy item list attribution.",
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "LABEL",
    "name": "info",
    "displayName": "The variable stores available item list information like \u003ci\u003eitem_list_id\u003c/i\u003e, \u003ci\u003eitem_list_name\u003c/i\u003e, \u003ci\u003eindex\u003c/i\u003e by \u003ci\u003eitem_id\u003c/i\u003e from the capturing event in a localStorage object. On all subsequent ecommerce events, it checks localStorage, adds available item list information to the \u003ci\u003eecommerce.items\u003c/i\u003e array and finally returns the whole \u003ci\u003eecommerce\u003c/i\u003e object.\u003cbr\u003e\u003cbr\u003e\nPREREQUESITES: All necessary \u003ca href\u003d\"https://developers.google.com/analytics/devguides/collection/ga4/ecommerce?hl\u003den\u0026client_type\u003dgtm\" target\u003d\"blank\"\u003eGA4 ecommerce dataLayer events\u003c/a\u003e are already set up on the page. \n\u003cbr\u003e\u003cbr\u003e\nDATA PRIVACY INFORMATION:  The tag sets a localStorage key \u003ci\u003etrkkn_gtm_item_list_attribution\u003c/i\u003e that contains the \u003ci\u003eitem_id\u003c/i\u003e with the corresponding item list information. The localStorage is deleted on the \u003ci\u003eUnset Event\u003c/i\u003e for clean data handling.\u003cbr\u003e\u003cbr\u003e"
  },
  {
    "type": "SELECT",
    "name": "mode",
    "displayName": "Mode",
    "macrosInSelect": true,
    "selectItems": [
      {
        "value": "enrichment",
        "displayValue": "enrichment"
      },
      {
        "value": "link_id",
        "displayValue": "link_id"
      }
    ],
    "simpleValueType": true,
    "help": "\u003cb\u003eenrichment:\u003c/b\u003e item list information is available in at least one ecommerce event like \u003ci\u003eselect_item\u003c/i\u003e or \u003ci\u003eview_item\u003c/i\u003e.\n \u003cbr\u003e\u003cbr\u003e\n\u003cb\u003elink_id:\u003c/b\u003e No item list information is available at all. You need to setup \u003ca href\u003d\"https://www.trkkn.com/insights/track-all-your-link-clicks-efficiently-with-TRKKN-link-id/\" target\u003d\"blank\"\u003eTRKKN link_id\u003c/a\u003e first in order to make this work!",
    "alwaysInSummary": true
  },
  {
    "type": "TEXT",
    "name": "capturingEvent",
    "displayName": "Capturing Event",
    "simpleValueType": true,
    "defaultValue": "select_item",
    "alwaysInSummary": true,
    "help": "\u003cb\u003eenrichment mode:\u003c/b\u003e The event, where item list information is present. Usually   \u003ci\u003eselect_item\u003c/i\u003e or \u003ci\u003eview_item\u003c/i\u003e.\n\u003cbr\u003e\u003cbr\u003e\n\u003cb\u003elink_id mode:\u003c/b\u003e  Usually the \u003ci\u003eview_item\u003c/i\u003e event, because when you click a product link in a product module (e.g search_results), you switch from a category to a product detail page. That is where link_id contains the information of the module (e.g. search_results) that has been clicked."
  },
  {
    "type": "TEXT",
    "name": "unsetEvent",
    "displayName": "Unset Event",
    "simpleValueType": true,
    "defaultValue": "purchase",
    "alwaysInSummary": true,
    "help": "Usually the \u003ci\u003epurchase\u003c/i\u003e event. For clean data handling, the localStorage \u003ci\u003etrkkn_gtm_item_list_attribution\u003c/i\u003e object will be deleted after every purchase."
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

const log = require("logToConsole");
const JSON = require("JSON");
const localStorage = require("localStorage");
const queryPermission = require("queryPermission");
const copyFromWindow = require("copyFromWindow");
const copyFromDataLayer = require("copyFromDataLayer");
const templateStorage = require("templateStorage");

const storageName = "trkkn_gtm_item_list_attribution";

if (
  !queryPermission("read_data_layer", "event") ||
  !queryPermission("read_data_layer", "ecommerce") ||
  !queryPermission("read_data_layer", "gtm.uniqueEventId") ||
  !queryPermission("access_globals", "read", "trkknSettings.page_link_id")
) {
  log("missing permissions");
  return undefined;
}

return main();

// eslint-disable-next-line no-unused-vars
function main() {
  const ecomObject = getEcomObjectFromDL();
  if (!ecomObject) {
    return undefined;
  }

  const gtmEventId = copyFromDataLayer("gtm.uniqueEventId");

  const cachedEcomObject = getCachedEcomObject(gtmEventId);
  if (cachedEcomObject) {
    return cachedEcomObject;
  }

  const eventName = copyFromDataLayer("event");

  if (eventName === data.capturingEvent) {
    storeItems(ecomObject, data.mode);
  }

  enrichEcomItems(ecomObject, data.mode);

  if (eventName === data.unsetEvent) {
    deleteItemFromStorage();
  }

  templateStorage.setItem("trkkn_gtm_ecom_obj", ecomObject);
  templateStorage.setItem("trkkn_valid_event_id", gtmEventId);
  return ecomObject;
}

function getEcomObjectFromDL() {
  const ecomObject = copyFromDataLayer("ecommerce") || {};

  if (!ecomObject.items || ecomObject.items.length <= 0) {
    log("ecom_object.items not set. Return undefined");
    return false;
  }

  return ecomObject;
}

function getCachedEcomObject(gtmEventId) {
  const cacheValidId = templateStorage.getItem("trkkn_valid_event_id");

  if (cacheValidId && gtmEventId !== cacheValidId) {
    templateStorage.removeItem("trkkn_valid_event_id");
    templateStorage.removeItem("trkkn_gtm_ecom_obj");
    log("resetting cache for gtmEventId:", gtmEventId);
    return false;
  }

  const ecomObjectCache = templateStorage.getItem("trkkn_gtm_ecom_obj");
  const eventIdCache = templateStorage.getItem("trkkn_valid_event_id");

  if (typeof ecomObjectCache === "object") {
    log("cache hit for gtmEventId:", gtmEventId, ecomObjectCache);
    return ecomObjectCache;
  }

  log("cache miss for gtmEventId:", gtmEventId, "in cache:", eventIdCache, ecomObjectCache);
  return false;
}

function storeItems(ecomObject, mode) {
  const linkId = getLinkId(mode);

  if (storingItemsNeeded(mode, linkId) === false) {
    log("not storing items:", mode, linkId);
    return;
  }

  const items = ecomObject.items;
  const itemsToStore = {};

  for (let i = 0; i < items.length; i += 1) {
    const itemId = items[i].item_id;

    if (mode === "link_id") {
      itemsToStore[itemId] = linkId;
      continue;
    }

    itemsToStore[itemId] = {
      item_list_id: items[i].item_list_id,
      item_list_name: items[i].item_list_name,
      index: items[i].index,
    };
  }

  const itemIdsStored = JSON.parse(localStorage.getItem(storageName)) || {};
  const updatedItemsToStore = mergeObjects(itemIdsStored, itemsToStore);

  localStorage.setItem(storageName, JSON.stringify(updatedItemsToStore));
}

function enrichEcomItems(ecomObject, mode) {
  const currentDlItems = ecomObject.items;
  const itemIdsStored = JSON.parse(localStorage.getItem(storageName)) || {};

  for (let i = 0; i < currentDlItems.length; i += 1) {
    const itemId = currentDlItems[i].item_id;
    const storedItem = itemIdsStored[itemId];

    if (!storedItem) {
      log("enrichEcomItems: no stored item for", itemId);
      continue;
    }

    if (mode === "link_id") {
      log("enrichEcomItems: enriching link id for", itemId, storedItem);
      currentDlItems[i].item_list_name = storedItem;
    }

    if (mode !== "link_id") {
      log("enrichEcomItems: enriching NON link id for", itemId, storedItem);
      currentDlItems[i] = mergeObjects(storedItem, currentDlItems[i]);
    }
  }
}

function deleteItemFromStorage() {
  log("deleting items from storage now.");
  localStorage.removeItem(storageName);
}

function getLinkId(mode) {
  if (mode !== "link_id") {
    return undefined;
  }

  const trkknSettings = copyFromWindow("trkknSettings") || {};
  return trkknSettings.page_link_id;
}

function storingItemsNeeded(mode, linkId) {
  if (mode !== "link_id" || !linkId) {
    return true;
  }

  if (linkId.indexOf("(reload)") >= 0 || linkId.indexOf("(back_forward)") >= 0) {
    return false;
  }

  return true;
}

function mergeObjects() {
  const result = {};

  for (let i = 0; i < arguments.length; i += 1) {
    // eslint-disable-next-line prefer-rest-params
    const currentObj = arguments[i];

    for (const key in currentObj) {
      // eslint-disable-next-line no-prototype-builtins
      if (currentObj.hasOwnProperty(key)) {
        result[key] = currentObj[key];
      }
    }
  }

  return result;
}


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_local_storage",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "trkkn_gtm_item_list_attribution"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_globals",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "trkknSettings"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "trkknSettings.page_link_id"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_template_storage",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_data_layer",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedKeys",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "keyPatterns",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "ecommerce.*"
              },
              {
                "type": 1,
                "string": "event"
              },
              {
                "type": 1,
                "string": "gtm.uniqueEventId"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: sampleTest
  code: |-
    const log = require('logToConsole');
    log('hello world');

    assertApi('logToConsole').wasCalled();


___NOTES___

Created on 6.12.2023, 16:37:17


