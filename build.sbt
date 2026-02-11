val scala3Version = "3.8.1"

lazy val root = project
  .in(file("."))
  .settings(
    name := "whatapp",
    version := "0.1.0-SNAPSHOT",
    scalaVersion := scala3Version,
    libraryDependencies +=
      ("org.lamport" % "tla2tools" % "1.8.0")
        .intransitive()
        .from("https://github.com/tlaplus/tlaplus/releases/download/v1.8.0/tla2tools.jar")

  )
