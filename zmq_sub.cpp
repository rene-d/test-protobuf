//
// zmq example
//

#include <assert.h>
#include <stdio.h>
#include <zmq.h>

int main()
{
    void *context = zmq_ctx_new();

    //  Socket to send start of batch message on
    void *sink = zmq_socket(context, ZMQ_SUB);

    zmq_bind(sink, "tcp://*:4567");
    zmq_setsockopt(sink, ZMQ_SUBSCRIBE, "TOPIC", 5);

    //  Process tasks forever
    while (1)
    {
        int more;
        int num_part = 0;
        do
        {
            /* Create an empty ØMQ message to hold the message part */
            zmq_msg_t part;
            int rc = zmq_msg_init(&part);
            assert(rc == 0);

            /* Block until a message is available to be received from socket */
            rc = zmq_msg_recv(&part, sink, 0);
            assert(rc != -1);

            if (num_part == 0)
                printf("message:\n");

            ++num_part;
            printf("  part %d: ", num_part);
            fwrite(zmq_msg_data(&part), zmq_msg_size(&part), 1, stdout);

            // Look if there is another part to come
            more = zmq_msg_more(&part);
            zmq_msg_close(&part);

            printf("%s\n", more ? " ..." : "|");

        } while (more);
    }

    zmq_close(sink);
    zmq_ctx_destroy(context);
    return 0;
}
