beforeEach(() => {
  throw new Error("oops");
});

it("a test", () => {
  expect(5).toBe(5);
});

it("b test", () => {
  expect(5).toBe(5);
});
