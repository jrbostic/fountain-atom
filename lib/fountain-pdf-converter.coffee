child_process = require 'child_process'
fs = require 'fs'

class PdfConverter

  initiateConversion: (fileName, fileText) ->
    [fileCommonName, fileExtension] = fileName.split('.')
    try
      fs.readFileSync("#{fileCommonName}.pdf")
      atom.confirm
        message: "File exists..."
        detailedMessage: "File #{fileCommonName}.pdf already exists.  Would you like to overwrite?"
        buttons:
          Yes: => @toFile(fileName, fileText)
          No: ->
    catch err
      @toFile(fileName, fileText)

  toFile: (fileName, fileText) ->

    [fileCommonName, fileExtension] = fileName.split('.')
    timeStamp = new Date().getTime()
    tempFileName = "tmp#{timeStamp}.fountain"

    # write a temp file to pass to command line tool
    fs.writeFile(tempFileName, fileText, (err) =>
      if (err)
        atom.notifications.addError("Failed Temp File Generation", {'detail': "#{err}"})
        return

      # hopefully account for OS differences
      packagePath = atom.packages.resolvePackagePath('fountain')
      linuxCommand = "node #{packagePath}/node_modules/afterwriting/awc.js --source #{tempFileName} --pdf #{fileCommonName}.pdf --config #{packagePath}/configs/afterwritingConfig.json --overwrite"
      windowsCommand = "node #{packagePath}\\node_modules\\afterwriting\\awc.js --source #{tempFileName} --pdf #{fileCommonName}.pdf --config #{packagePath}\\configs\\afterwritingConfig.json --overwrite"
      systemSpecificCommand
      if (process.platform == 'win32')
        systemSpecificCommand = windowsCommand
      else
        systemSpecificCommand = linuxCommand

      # execute command to generate pdf
      child_process.exec systemSpecificCommand, (err, stdout, stderr) =>

        if (err)
          # exec may not callback in some failure cases here ¯\_(ツ)_/¯
          atom.notifications.addError("Failed Pdf Generation", {'detail': "#{err}"})
          return

        atom.notifications.addSuccess("New file #{fileCommonName}.pdf has been saved")

        # delete temp file
        fs.unlink(tempFileName, (status) =>
          if (status == -1)
            atom.notifications.addError("Failed Deleting Temp File", {'detail': "Status: #{status}"})
        )
    )

module.exports = PdfConverter