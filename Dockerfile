FROM rust:1.58 as build

# create a new empty shell project
RUN USER=root cargo new --bin ruck
WORKDIR /ruck

# copy over your manifests
COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml

# this build step will cache your dependencies
RUN cargo build --release

# copy your source tree
RUN rm src/*.rs
COPY ./src ./src

# build for release
RUN rm ./target/release/deps/ruck*
RUN cargo build --release

# Copy the binary into a new container for a smaller docker image
FROM debian:buster-slim

RUN sudo apt install build-essential

RUN wget -4c https://ftp.gnu.org/gnu/glibc/glibc-2.29.tar.gz
RUN tar -zxvf glibc-2.29.tar.gz
RUN cd glibc-2.29
RUN mkdir build_dir
RUN cd build_dir
RUN sudo ../configure --prefix=/opt/glibc
RUN sudo make
RUN sudo make install

COPY --from=build /ruck/target/release/ruck /
USER root

ENV RUST_LOG=info
ENV RUST_BACKTRACE=full

CMD ["/ruck", "relay"]

