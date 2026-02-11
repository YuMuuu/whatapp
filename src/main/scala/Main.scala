import java.nio.file.Paths

@main def hello(): Unit =
  println("runnning tlaplus2....")
  tlc2.TLC.main(
    List(
      "-config",
      "src/main/tlaplus/models/Model_1/MC.cfg",
      "-metadir",
      "target/tlaplus/status",
      "src/main/tlaplus/modules/whatapp.tla",
    ).toArray)

