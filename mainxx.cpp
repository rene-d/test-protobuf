#include <fstream>
#include <iostream>
#include "foo.pb.h"

using namespace std;

int main()
{
    Foo  foo;
    Foo_Bar *bar;
    Foo_Bar_Beer *beer;

    foo.set_seed(0xbabe);

    bar = foo.add_bar();
    bar->set_name("uh");
    bar->set_value(0xb00b);

    beer = bar->add_beer();
    beer->set_a("blah");
    beer->set_b(0xdead);

    beer = bar->add_beer();
    beer->set_a("doh");
    beer->set_b(0xbeef);

    bar = foo.add_bar();
    bar->set_name("ha");
    bar->set_value(0xcafe);

    ofstream out("data.bin");
    if (foo.SerializeToOstream(&out))
        cout << "len: " << out.tellp() << endl;
    out.close();
}
