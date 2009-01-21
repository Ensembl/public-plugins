/* -*- Mode: C; tab-width: 4; c-basic-offset: 4; indent-tabs-mode: nil -*- */
/*
 * Tag function for Memcached.
 *
 * $Id: tag.c,v 1.1 2008/10/02 13:30:43 eb4 Exp $
 */
#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <errno.h>
#include <assert.h>
#ifdef HAVE_MALLOC_H
#include <malloc.h>
#endif
#ifdef HAVE_STRING_H
#include <string.h>
#endif
#include "memcached.h"
#include "splaytree.h"

/******** function declaration ********/

void tag_init(void);
int do_tag_insert(char *tag_name, const uint8_t ntag, char *key_name, const uint8_t nkey);
bool do_tag_delete(const char *tag_name, const uint8_t ntag);
int do_tags_delete(const char *tags[], const size_t *ntags[], const uint8_t n);
int delete_by_tags(splay_tree *branch, const char *tags[], const size_t *ntags[], const uint8_t n);
tag *do_tag_find(const char *tag_name, const uint8_t ntag);
static tag** _hashtag_before (const char *tag_name, const uint8_t ntag);
char *do_tag_dump(int *len);
void do_tag_reverse_del_key(splay_tree *tags_tree, snode* key_sn);

/******** variable definition ********/

typedef unsigned long int  ub4;   /* unsigned 4-byte quantities */
typedef unsigned      char ub1;   /* unsigned 1-byte quantities */

/* how many powers of 2's worth of buckets we use */
static unsigned int tag_hashpower = 16;

#define hashsize(n) ((ub4)1<<(n))
#define hashmask(n) (hashsize(n)-1)

/* Hash table. This is where we look. */
static tag** hashtable = 0;

/* Number of tags in the hash table. */
static unsigned int hash_tags = 0;

/******** function definition ********/

void tag_init(void) {
    unsigned int hash_size = hashsize(tag_hashpower) * sizeof(void*);
    hashtable = calloc(1, hash_size);
    if (!hashtable) {
        fprintf(stderr, "Failed to init hashtable.\n");
        exit(EXIT_FAILURE);
    }
}

/*
return :
    0 - failed
    1 - succ
*/
int do_tag_insert(char *tag_name, const uint8_t ntag, char *key_name, const uint8_t nkey) {
    long long hv = 0;
    unsigned int bucket = 0;
    snode *sn = NULL;
    tag *ta = NULL;
    item *it = NULL;
    int size = 0;

    if (NULL == tag_name || '\0' == tag_name[0] || NULL == key_name || '\0' == key_name[0]) {
        fprintf(stderr, "error params\n");
        return 0;
    }

    //reverse tree : item->tag
    it = assoc_find(key_name, nkey);
    if (it) {
        size = sizeof(snode) + ntag + 1;
        sn = calloc(1, size);
        if (NULL == sn) {
            fprintf(stderr, "Out of memory in do_tag_insert 3\n");
            return 0;
        }
        sn->nstr = ntag;
        strncpy(GET_name(sn), tag_name, ntag);
        GET_name(sn)[ntag] = '\0';      /* because strncpy() sucks */

        //add tag name into item struct
        hv = hash(tag_name, ntag, 0);
        it->tags = splaytree_insert(it->tags, hv, (void*)sn);
    }
    else {
        //item not exist, just ignore it! return succ.
        return 1;
    }

    //tag->key
    ta = do_tag_find(tag_name, ntag);
    if (NULL == ta) {
        size = sizeof(tag) + ntag + 1;
        ta = calloc(1, size);
        if (NULL == ta) {
            fprintf(stderr, "Out of memory in do_tag_insert 1 \n");
            return 0;
        }
        ta->ntag = ntag;
        strncpy(TAG_name(ta), tag_name, ntag);
        TAG_name(ta)[ntag] = '\0';      /* because strncpy() sucks */

        // add tag into hash
        hv = hash(TAG_name(ta), ta->ntag, 0);
        bucket = hv & hashmask(tag_hashpower - 1);
        ta->h_next = hashtable[bucket];
        hashtable[bucket] = ta;
        hash_tags++;
    }

    size = sizeof(snode) + nkey + 1;
    sn = calloc(1, size);
    if (NULL == sn) {
        fprintf(stderr, "Out of memory in do_tag_insert 2\n");
        return 0;
    }
    sn->nstr = nkey;
    strncpy(GET_name(sn), key_name, nkey);
    GET_name(sn)[nkey] = '\0';      /* because strncpy() sucks */

    //add key name for tag
    hv = hash(key_name, nkey, 0);
    ta->keys = splaytree_insert(ta->keys, hv, (void*)sn);

    return 1;
}

/*
return:
    false - failed
    true - succ
*/
bool do_tag_delete(const char *tag_name, const uint8_t ntag) {
    tag **before = NULL, *prev = NULL, *nxt = NULL, *pt = NULL;
    snode *key_sn = NULL, *temp = NULL, *ptsn = NULL, *pnext = NULL;
    item *it = NULL;
    char *key_name = NULL, *other_tname = NULL;
    uint8_t nkey = 0, other_ntag = 0;
    int size = 0;
    long long hv = 0;
    splay_tree *root = NULL;

    if (NULL == tag_name || '\0' == tag_name[0]) {
        fprintf(stderr, "error params in do_tag_delete\n");
        return 0;
    }

    before = _hashtag_before(tag_name, ntag);
    prev = *before;
    if (prev) {
        nxt = prev->h_next;
        prev->h_next = 0;
        root = prev->keys;
        prev->is_deling = true;

        while(NULL != root) {
            key_sn = (snode*)root->data;
 
            key_name = GET_name(key_sn);
            nkey = key_sn->nstr;

            if (settings.detail_enabled) {
                stats_prefix_record_delete(key_name);
            }

            it = assoc_find(key_name, nkey);
            if (it) {
            	it->refcount++;

                //reverse del
                do_tag_reverse_del_key(it->tags, key_sn);
                
                //delete item
                item_unlink(it);
                item_remove(it);      // release our reference
            }

            //delete key_name
            root = splaytree_delete(root, root->key, root->data);
        }
 
        //delete tag from hash
        free(prev);
        *before = prev = NULL;

        *before = nxt;
        hash_tags--;
    }
    else {
        return false;       //not found
    }

    return true;            //delete
}

/* Obsolete */
int delete_by_tags(splay_tree *branch, const char *tags[], const size_t *ntags[], const uint8_t n) {
    snode *key_sn = NULL;
    item *it = NULL;
    char *key_name = NULL;
    uint8_t nkey = 0;
    long long hv = 0;
    int ndeleted = 0;

    if (NULL == branch) {
    	return 0;
    }
    
    ndeleted += delete_by_tags(branch->left, tags, ntags, n);
	ndeleted += delete_by_tags(branch->right, tags, ntags, n);

    key_sn = (snode*)branch->data;

    key_name = GET_name(key_sn);
    nkey = key_sn->nstr;

    if (settings.detail_enabled) {
        stats_prefix_record_delete(key_name);
    }

    it = assoc_find(key_name, nkey);
    
    if (it) {

    	uint8_t i;
    	bool item_has_all_tags = true;
    	
    	for (i=1; i<n; i++) {
            hv = hash(tags[i], ntags[i], 0);
            item_has_all_tags = true; //splaytree_find(it->tags, hv);
    	}
    	
    	if (item_has_all_tags) {
    		it->refcount++;

    		//reverse del
            //do_tag_reverse_del_key(it->tags, key_sn);

            //delete item
            item_unlink(it);
            item_remove(it);      // release our reference

    	}
    	
    }
    
    ndeleted += 1;
    return ndeleted;
}


/*
Obsolete
return:
    number of items deleted
*/
int do_tags_delete(const char *tags[], const size_t *ntags[], const uint8_t n) {
    tag **before = NULL, *prev = NULL;
    splay_tree *root = NULL;

    /*TODO: find litest tag*/
    char *tag_name = tags[0];
    uint8_t ntag = ntags[0];

    if (NULL == tag_name || '\0' == tag_name[0]) {
        fprintf(stderr, "error params in do_tag_delete\n");
        return 0;
    }

    before = _hashtag_before(tag_name, ntag);
    prev = *before;
    if (prev) {
        root = prev->keys;
        return delete_by_tags(root, tags, ntags, n);
    } else {
        return 0;
    }
}


void do_tag_reverse_del_key(splay_tree *tags_tree, snode* key_sn) {
    tag *ta = NULL, **before = NULL, *prev = NULL, *nxt = NULL;
    long long hv = 0;
    char *tag_name = NULL, *key_name = NULL;
    uint8_t ntag = 0, nkey = 0;
    snode *sn = NULL;

    if (NULL == tags_tree) {
        return;
    }
    do_tag_reverse_del_key(tags_tree->left, key_sn);
    do_tag_reverse_del_key(tags_tree->right, key_sn);

    if (NULL == key_sn) {
        fprintf(stderr, "error params in do_tag_reverse_del_key\n");
        return;
    }
    key_name = GET_name(key_sn);
    nkey = key_sn->nstr;

    for(sn=(snode*)tags_tree->data; NULL!=sn; sn=sn->next) {
        tag_name = GET_name(sn);
        ntag = sn->nstr;

        ta = do_tag_find(tag_name, ntag);
        if (ta) {
            if (true == ta->is_deling) {
                return;
            }
            hv = hash(key_name, nkey, 0);
            ta->keys = splaytree_delete(ta->keys, hv, (void*)key_sn);

            //delete empty tag
            if (NULL == ta->keys) {
                before = _hashtag_before(tag_name, ntag);
                prev = *before;

                if (prev) {
                    //delete tag from hash
                    nxt = prev->h_next;

                    free(prev);
                    prev = NULL;

                    *before = nxt;
                    hash_tags--;
                }
            }
        }
    }

    return;
}

/*
return :
    NULL - not found
    other - found
*/
/* returns the address of the tag pointer before the tag.  if *tag == 0,
   the tag wasn't found */
static tag** _hashtag_before (const char *tag_name, const uint8_t ntag) {
    long long hv = 0;
    tag **pos = NULL;
    unsigned int bucket = 0;

    if (NULL == tag_name || '\0' == tag_name[0]) {
        fprintf(stderr, "error params\n");
        return 0;
    }

    hv = hash(tag_name, ntag, 0);
    bucket = hv & hashmask(tag_hashpower - 1);
    pos = &hashtable[bucket];

    while (*pos &&
            ((ntag != (*pos)->ntag) || memcmp(tag_name, TAG_name(*pos), ntag))) {
        pos = &(*pos)->h_next;
    }

    return pos;
}

/*
return:
    NULL - not found
    other - found
*/
tag *do_tag_find(const char *tag_name, const uint8_t ntag) {
    long long hv = 0;
    tag *ta = NULL;
    unsigned int bucket = 0;

    if (NULL == tag_name || '\0' == tag_name[0]) {
        fprintf(stderr, "error params\n");
        return 0;
    }

    hv = hash(tag_name, ntag, 0);
    bucket = hv & hashmask(tag_hashpower - 1);
    ta = hashtable[bucket];

    while (ta) {
        if ((ntag == ta->ntag) &&
                (0 == memcmp(tag_name, TAG_name(ta), ntag))) {
            return ta;
        }
        ta = ta->h_next;
    }
    return 0;
}

#define MAX_BUF_SIZE 8192
void spt_recursion(splay_tree *sp, char *buf, int *pos) {
    snode *sn = NULL;

    if(NULL == sp || NULL == buf || NULL == pos)
        return;

    for(sn=(snode*)sp->data; NULL!=sn; sn=sn->next) {
        (*pos) += snprintf(buf+(*pos), MAX_BUF_SIZE-(*pos), " %s", GET_name(sn));
    }

    spt_recursion(sp->left, buf, pos);
    spt_recursion(sp->right, buf, pos);

    return;
}

/*
return:
    NULL - fail
    NOT-NULL - succ
*/
char *do_tag_dump(int *len) {
    char *buf = NULL;
    tag *ta = NULL;
    snode *sn = NULL;
    splay_tree *sp = NULL;
    int pos = 0;
    int i = 0;

    buf = calloc(1, MAX_BUF_SIZE);
    if (0 == buf) {
        fprintf(stderr, "OUT OF MEMORY in do_tag_dump\n");
        return NULL;
    }

    pos += snprintf(buf+pos, MAX_BUF_SIZE-pos, "\r\n");

    for (i = 0; i < hashsize(tag_hashpower); i++) {
        for (ta = hashtable[i]; NULL != ta; ta = ta->h_next) {
            pos += snprintf(buf+pos, MAX_BUF_SIZE-pos, "%s :", TAG_name(ta));
            spt_recursion(ta->keys, buf, &pos);
            pos += snprintf(buf+pos, MAX_BUF_SIZE-pos, "\r\n");
        }
    }

    pos += snprintf(buf+pos, MAX_BUF_SIZE-pos, "END\r\n");

    *len = pos;

    return buf;
}

