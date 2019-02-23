#include "foo.pb-c.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

int main()
{
    srand(time(NULL));

    // ---- foo
    Foo *foo = (Foo *)calloc(1, sizeof(Foo));
    foo__init(foo);
    // foo->seed = rand() % 10000;
    foo->seed = 0xbabe;
    foo->n_bar = 2;
    foo->bar = (Foo__Bar **)calloc(foo->n_bar, sizeof(Foo__Bar *));

    // ---- bar[0]
    foo->bar[0] = (Foo__Bar *)calloc(1, sizeof(Foo__Bar));
    foo__bar__init(foo->bar[0]);
    foo->bar[0]->name = strdup("uh");
    foo->bar[0]->value = 0xb00b;
    foo->bar[0]->n_beer = 2;
    foo->bar[0]->beer = (Foo__Bar__Beer **)calloc(foo->bar[0]->n_beer, sizeof(Foo__Bar__Beer *));

    // ---- bar[0].beer[0]
    foo->bar[0]->beer[0] = (Foo__Bar__Beer *)calloc(1, sizeof(Foo__Bar__Beer));
    foo__bar__beer__init(foo->bar[0]->beer[0]);
    foo->bar[0]->beer[0]->a = strdup("blah");
    foo->bar[0]->beer[0]->b = 0xdead;

    // ---- bar[0].beer[1]
    foo->bar[0]->beer[1] = (Foo__Bar__Beer *)calloc(1, sizeof(Foo__Bar__Beer));
    foo__bar__beer__init(foo->bar[0]->beer[1]);
    foo->bar[0]->beer[1]->a = strdup("doh");
    foo->bar[0]->beer[1]->b = 0xbeef;

    // ---- bar[1]
    foo->bar[1] = (Foo__Bar *)calloc(1, sizeof(Foo__Bar));
    foo__bar__init(foo->bar[1]);
    foo->bar[1]->n_beer = 0;
    foo->bar[1]->name = strdup("ha");
    foo->bar[1]->value = 0xcafe;

    // ---- size/pack
    size_t len = foo__get_packed_size(foo);
    printf("len: %zu\n", len);

    uint8_t *buf = (uint8_t *)malloc(len);
    foo__pack(foo, buf);
    FILE *f = fopen("data.bin", "wb");
    fwrite(buf, len, 1, f);
    fclose(f);

    // take care of the memory
    for (int i = 0; i < foo->n_bar; ++i)
    {
        Foo__Bar *bar = foo->bar[i];
        free(bar->name);
        for (int j = 0; j < bar->n_beer; ++j)
        {
            Foo__Bar__Beer *beer = bar->beer[j];
            free(beer->a);
            free(beer);
        }
        free(bar);
    }
    free(foo);

    return 0;
}
