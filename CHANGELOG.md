# 0.1.0
* base implementation

# 0.1.1
* changelog creation
* docs updated
* view/2 updated to use a unique variable before matching, avoiding repeated function call when it is the value to be matched on
* pattern/1 : changed ast traversal from pre to post to avoid infinite loops during compilation (was present but forgotten in the changelog)

# 0.2.0
* docs updated
* reorganised the order of the patterns definitions, this allows to set the doc attribute for the version used by the programmer, and to hide the internal version used by `view`
* added a vanilla definition for unidirectional pattern using a view, this permit to set a doc usable by the programmer, improve discoverability, and signal with a better error message when improperly used (from unknown definition to custom raise)
* internal changes
* guards can now be used with `view`
