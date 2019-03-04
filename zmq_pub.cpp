//
// zmq example: PUB with socket monitoring
//

#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <zmq.h>

#define timespec_diff(tvp, uvp, vvp)                      \
    do                                                    \
    {                                                     \
        (vvp)->tv_sec = (tvp)->tv_sec - (uvp)->tv_sec;    \
        (vvp)->tv_nsec = (tvp)->tv_nsec - (uvp)->tv_nsec; \
        if ((vvp)->tv_nsec < 0)                           \
        {                                                 \
            (vvp)->tv_sec--;                              \
            (vvp)->tv_nsec += 1000000000;                 \
        }                                                 \
    } while (0)

void send(void *socket, const char *text)
{
    /* Create an empty ØMQ message to hold the message part */
    zmq_msg_t topic, part;

    zmq_msg_init_data(&topic, (void *)"TOPIC", 5, NULL, NULL);
    zmq_msg_init_data(&part, (void *)text, strlen(text), NULL, NULL);

    zmq_msg_send(&topic, socket, ZMQ_SNDMORE);
    zmq_msg_send(&part, socket, 0);

    zmq_msg_close(&topic);
    zmq_msg_close(&part);
}

int get_monitor_event(void *monitor, int *value, char **address)
{
    // First frame in message contains event number and value
    zmq_msg_t msg;
    zmq_msg_init(&msg);
    if (zmq_msg_recv(&msg, monitor, 0) == -1)
        return -1; // Interrupted, presumably
    assert(zmq_msg_more(&msg));

    uint8_t *data = (uint8_t *)zmq_msg_data(&msg);
    uint16_t event = *(uint16_t *)(data);
    if (value)
        *value = *(uint32_t *)(data + 2);

    // Second frame in message contains event address
    zmq_msg_init(&msg);
    if (zmq_msg_recv(&msg, monitor, 0) == -1)
        return -1; // Interrupted, presumably
    assert(!zmq_msg_more(&msg));

    if (address)
    {
        uint8_t *data = (uint8_t *)zmq_msg_data(&msg);
        size_t size = zmq_msg_size(&msg);
        *address = (char *)malloc(size + 1);
        memcpy(*address, data, size);
        (*address)[size] = 0;
    }
    return event;
}

int main(int argc, char *argv[])
{
    int rc;
    void *context = zmq_ctx_new();

    //  Socket to send start of batch message on
    void *socket = zmq_socket(context, ZMQ_PUB);

    // monitor connection event
    zmq_socket_monitor(socket, "inproc://monitor-client", ZMQ_EVENT_HANDSHAKE_SUCCEEDED);

    // Create a socket for collecting monitor events
    void *client_mon = zmq_socket(context, ZMQ_PAIR);
    assert(client_mon);

    // Connect these to the inproc endpoints so they'll get events
    rc = zmq_connect(client_mon, "inproc://monitor-client");
    assert(rc == 0);

    zmq_connect(socket, "tcp://localhost:4567");

    // socket is not connected yet (asynchronous operation)
    send(socket, "lost");

    zmq_pollitem_t items[1];
    items[0].socket = client_mon;
    items[0].events = ZMQ_POLLIN;

    struct timespec start, end, delta;
    clock_gettime(CLOCK_MONOTONIC, &start);

    // wait 1 s for handshake
    rc = zmq_poll(items, 1, 1000);

    clock_gettime(CLOCK_MONOTONIC, &end);
    timespec_diff(&end, &start, &delta);

    printf("poll: %d %ld.%09lds\n", rc, (long)delta.tv_sec, (long)delta.tv_nsec);

    if (rc == 1) // number of pollitem_t
    {
        // read the event (ZMQ_EVENT_HANDSHAKE_SUCCEEDED)
        char *address = NULL;
        int event, value = 0;
        event = get_monitor_event(client_mon, &event, &address);
        printf("monitor: %d %d %s\n", event, value, address);
        if (address)
            free(address);

        // send a message, will not be lost
        send(socket, "got it? 🤪");

        send(socket, "BYE");
    }

    zmq_close(client_mon);
    zmq_close(socket);
    zmq_ctx_destroy(context);

    return 0;
}
