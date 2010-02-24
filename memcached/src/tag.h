#ifndef TAG_H
#define TAG_H

#include "assoc.h"

/******** function declaration ********/
void tag_init(void);
int do_tag_insert(char *tag_name, const uint8_t ntag, char *key_name, const uint8_t nkey);
bool do_tag_delete(const char *tag_name, const uint8_t ntag);
int do_tags_delete(const char *tags[], const size_t *ntags[], const uint8_t n);
tag *do_tag_find(const char *tag_name, const uint8_t ntag);
char *do_tag_dump(int *len);
void do_tag_reverse_del_key(splay_tree *tags_tree, snode* key_sn);

#endif //TAG_H

