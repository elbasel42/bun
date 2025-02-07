/**
 * @see https://nodejs.org/api/net.html#class-netsocketaddress
 */
import { SocketAddress } from "node:net";

describe("SocketAddress", () => {
  it("is named SocketAddress", () => {
    expect(SocketAddress.name).toBe("SocketAddress");
  });

  it("is newable", () => {
    // @ts-ignore -- types are wrong. default is kEmptyObject.
    expect(new SocketAddress()).toBeInstanceOf(SocketAddress);
  });

  it("is not callable", () => {
    // @ts-ignore -- types are wrong.
    expect(() => SocketAddress()).toThrow(TypeError);
  });
});

describe("SocketAddress.isSocketAddress", () => {
  it("is a function that takes 1 argument", () => {
    expect(SocketAddress).toHaveProperty("isSocketAddress");
    expect(SocketAddress.isSocketAddress).toBeInstanceOf(Function);
    expect(SocketAddress.isSocketAddress).toHaveLength(1);
  });

  it("has the correct property descriptor", () => {
    const desc = Object.getOwnPropertyDescriptor(SocketAddress, "isSocketAddress");
    expect(desc).toEqual({
      value: expect.any(Function),
      writable: true,
      enumerable: false,
      configurable: true,
    });
  });
});

describe("SocketAddress.parse", () => {
  it("is a function that takes 1 argument", () => {
    expect(SocketAddress).toHaveProperty("parse");
    expect(SocketAddress.parse).toBeInstanceOf(Function);
    expect(SocketAddress.parse).toHaveLength(1);
  });

  it("has the correct property descriptor", () => {
    const desc = Object.getOwnPropertyDescriptor(SocketAddress, "parse");
    expect(desc).toEqual({
      value: expect.any(Function),
      writable: true,
      enumerable: false,
      configurable: true,
    });
  });
});

describe("SocketAddress.prototype.address", () => {
  it("has the correct property descriptor", () => {
    const desc = Object.getOwnPropertyDescriptor(SocketAddress.prototype, "address");
    expect(desc).toEqual({
      get: expect.any(Function),
      set: undefined,
      enumerable: false,
      configurable: true,
    });
  });
});

describe("SocketAddress.prototype.port", () => {
  it("has the correct property descriptor", () => {
    const desc = Object.getOwnPropertyDescriptor(SocketAddress.prototype, "port");
    expect(desc).toEqual({
      get: expect.any(Function),
      set: undefined,
      enumerable: false,
      configurable: true,
    });
  });
});

describe("SocketAddress.prototype.family", () => {
  it("has the correct property descriptor", () => {
    const desc = Object.getOwnPropertyDescriptor(SocketAddress.prototype, "family");
    expect(desc).toEqual({
      get: expect.any(Function),
      set: undefined,
      enumerable: false,
      configurable: true,
    });
  });
});

describe("SocketAddress.prototype.flowlabel", () => {
  it("has the correct property descriptor", () => {
    const desc = Object.getOwnPropertyDescriptor(SocketAddress.prototype, "flowlabel");
    expect(desc).toEqual({
      get: expect.any(Function),
      set: undefined,
      enumerable: false,
      configurable: true,
    });
  });
});

describe("SocketAddress.prototype.toJSON", () => {
  it("is a function that takes 0 arguments", () => {
    expect(SocketAddress.prototype).toHaveProperty("toJSON");
    expect(SocketAddress.prototype.toJSON).toBeInstanceOf(Function);
    expect(SocketAddress.prototype.toJSON).toHaveLength(0);
  });

  it("has the correct property descriptor", () => {
    const desc = Object.getOwnPropertyDescriptor(SocketAddress.prototype, "toJSON");
    expect(desc).toEqual({
      value: expect.any(Function),
      writable: true,
      enumerable: false,
      configurable: true,
    });
  });
});
