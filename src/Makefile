all: args-probe args-advise.so

args-probe:
	gcc -std=gnu99 -O3 -o args-probe args-probe.c

args-advise.so:
	gcc -std=gnu99 -O3 -fPIC -shared -o args-advise.so args-advise.c

clean:
	rm -rf args-probe args-advise.so
