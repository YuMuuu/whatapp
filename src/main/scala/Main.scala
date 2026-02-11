@main def hello(): Unit =
  println("runnning tlaplus2....")
  tlc2.TLC.main(
    List(
      "src/main/tlaplus/modules/whatapp.tla",
      "-config",
      "src/main/tlaplus/models/Model_1/MC.cfg",
      "-metadir",
      "target/states/"
    ).toArray)

