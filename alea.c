#include "foo.pb-c.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static const char *phrases[] = {"d'oh", "donut", "mmmmmmmm", "uh", "woohoo", "blah", "maggie", "homer", "bart" };

char *phrase()
{
    return strdup(phrases[rand() % (sizeof(phrases) / sizeof(phrases[0]))]);
}

int main(int argc, char *argv[])
{
    unsigned int seed;

    if (argc >= 2)
        seed = strtoul(argv[1], NULL, 0);
    else
        seed = time(NULL);

    srand(seed);

    printf("foo: seed=%u\n", seed);

    // ---- foo
    Foo *foo = (Foo *)calloc(1, sizeof(Foo));
    foo__init(foo);
    foo->seed = seed;
    foo->n_bar = rand() % 10;
    foo->bar = (Foo__Bar **)calloc(foo->n_bar, sizeof(Foo__Bar *));

    printf("   bar: %zu\n", foo->n_bar);

    for (int i = 0; i < foo->n_bar; ++i)
    {
        // ---- bar[0]
        Foo__Bar *bar = (Foo__Bar *)calloc(1, sizeof(Foo__Bar));
        foo->bar[i] = bar;
        foo__bar__init(bar);
        bar->name = phrase();
        bar->value = 0xb00b + i;
        bar->n_beer = rand() % 10;
        bar->beer = (Foo__Bar__Beer **)calloc(bar->n_beer, sizeof(Foo__Bar__Beer *));

        printf("      beer: %zu\n", bar->n_beer);

        for (int j = 0; j < bar->n_beer; ++j)
        {
            // ---- bar[0].beer[0]
            Foo__Bar__Beer *beer = (Foo__Bar__Beer *)calloc(1, sizeof(Foo__Bar__Beer));
            bar->beer[j] = beer;
            foo__bar__beer__init(beer);
            beer->a = phrase();
            beer->b = 0xdead + i * bar->n_beer +  j;
        }
    }

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
