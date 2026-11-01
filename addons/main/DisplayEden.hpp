class ctrlMenuStrip;
class Display3DEN {
    class Controls {
        class MenuStrip: ctrlMenuStrip {
            class Items {
                items[] += {QUOTE(PREFIX)};
                class PREFIX {
                    text = JMFSB_TOOLBAR;
                    items[] += {
                        QGVAR(Wiki)
                    };
                };
                class GVAR(Wiki) {
                    text = JMFSB_TOOLBAR_WIKI;
                    picture = "\a3\3DEN\Data\Controls\ctrlMenu\link_ca.paa";
                    weblink = "https://github.com/Joint-Multi-Functional-Strike-Battalion/";
                    opensNewWindow = 1;
                };
            };
        };
    };
};
