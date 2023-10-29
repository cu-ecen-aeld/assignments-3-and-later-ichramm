#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{
    struct thread_data *data = (struct thread_data *) thread_param;

    usleep(1000 * data->wait_to_obtain_ms);

    if (pthread_mutex_lock(data->mutex) != 0) {
        ERROR_LOG("pthread_mutex_lock failed");
        return thread_param;
    }

    usleep(1000 * data->wait_to_release_ms);

    if (pthread_mutex_unlock(data->mutex) != 0) {
        ERROR_LOG("pthread_mutex_unlock failed");
        return thread_param;
    }

    data->thread_complete_success = true;

    return thread_param;
}

bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    struct thread_data *data = malloc(sizeof(struct thread_data));
    if (data == NULL) {
        ERROR_LOG("malloc failed");
        return false;
    }

    data->wait_to_obtain_ms = wait_to_obtain_ms;
    data->wait_to_release_ms = wait_to_release_ms;
    data->mutex = mutex;
    data->thread_complete_success = false;

    int ret = pthread_create(thread, NULL, threadfunc, data);
    if (ret != 0) {
        ERROR_LOG("pthread_create failed");
        free(data);
        return false;
    }

    return true;
}
