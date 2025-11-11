FROM fedora:41

RUN dnf install -y ldc dub && dnf clean all

WORKDIR /build
COPY . .
RUN dub build --build=release

FROM fedora:41

RUN dnf install -y ldc && dnf clean all

WORKDIR /app
COPY --from=0 /build/mywormnet2 .
COPY --from=0 /build/mywormnet2-sample.ini .
COPY --from=0 /build/motd-sample.txt .
COPY --from=0 /build/news-sample.html .
COPY --from=0 /build/wwwroot ./wwwroot

EXPOSE 6667 8081

CMD ["./mywormnet2"]
