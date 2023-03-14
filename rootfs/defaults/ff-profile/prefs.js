// Enable use of userChrome.css.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Open links in current tab.
user_pref("browser.link.open_newwindow", 1);
user_pref("browser.link.open_newwindow.restriction", 1);

// Disable warning on closing multiple tabs.
user_pref("browser.tabs.warnOnClose", false);

// Disable the privacy notice page on first start.
user_pref("datareporting.policy.firstRunURL", "");

// Remove buttons from toolbar.
//user_pref("browser.pageActions.persistedActions", "{\"version\":1,\"ids\":[\"bookmark\",\"pinTab\",\"bookmarkSeparator\",\"copyURL\",\"emailLink\",\"addSearchEngine\",\"sendToDevice\",\"pocket\",\"screenshots_mozilla_org\",\"webcompat-reporter_mozilla_org\"],\"idsInUrlbar\":[]}");
//user_pref("browser.uiCustomization.state", "{\"placements\":{\"widget-overflow-fixed-list\":[],\"nav-bar\":[\"back-button\",\"forward-button\",\"stop-reload-button\",\"urlbar-container\",\"downloads-button\"],\"toolbar-menubar\":[\"menubar-items\"],\"TabsToolbar\":[\"tabbrowser-tabs\",\"new-tab-button\",\"alltabs-button\"],\"PersonalToolbar\":[\"personal-bookmarks\"]},\"seen\":[\"developer-button\"],\"dirtyAreaCache\":[\"nav-bar\",\"toolbar-menubar\",\"TabsToolbar\",\"PersonalToolbar\"],\"currentVersion\":16,\"newElementCount\":2}");

