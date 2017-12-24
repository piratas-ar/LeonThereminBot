class TelegramWebhooksController < Telegram::Bot::UpdatesController
  def start(*)
    respond_with :message, text: t('.hi')
  end

  # TODO responder algo
  def message(message)
    # Contenedores de archivos
    files = %w(document voice)
    # Encontrar alguno de los contenedores de archivos
    found = message.keys.map { |k| k if files.include? k }.compact.first

    # Chequear si el mensaje no contiene ningún archivo
    unless found
      respond_with :message, text: t('.nothing')
      return
    end

    # Descargar el archivo
    file = download_file_from message, where: found

    # Si no conseguimos nada, nos vamos
    unless file
      respond_with :message, text: t('.not_found')
      return
    end

    # Salir si no es un archivo válido
    unless audio? file.path
      respond_with :message, text: t('.invalid')
      close_and_remove file
      return
    end

    # Guardar la conversión en un archivo temporal en memoria RAM
    #
    # (Las distros modernas montan /tmp como tmpfs)
    mp3 = "/tmp/#{message[found]['file_id']}.mp3"
    # Abrir el archivo con ffmpeg
    convert = FFMPEG::Movie.new(file.path)

    # Salir si no es un archivo válido
    unless convert.valid? && !convert.audio_streams.empty?
      respond_with :message, text: t('.invalid')
      close_and_remove file
      return
    end

    # Convertir a MP3
    respond_with :message, text: t('.ok')
    converted = convert.transcode(mp3)
    mp3 = File.open(mp3)

    # Enviar el archivo
    respond_with :document, document: mp3

    # Cerrar los archivos abiertos y eliminarlos!
    [ mp3, file ].each { |f| close_and_remove f }
  end

  private

  # Descargar el archivo contenido en el mensaje
  #
  # https://stackoverflow.com/a/32679930
  def download_file_from(message, where:)
    # Pedir a la API de Telegram que cree el archivo
    get = bot.get_file message[where]
    url = "https://api.telegram.org/file/bot#{bot.token}/#{get['result']['file_path']}"

    # Y descargarlo temporalmente
    open(url)
  end

  def audio?(path)
    %w(audio video).include? type?(path)
  end

  def type?(path)
    FileMagic.new(FileMagic::MAGIC_MIME).file(path).split('/').first
  end

  def close_and_remove(file)
    file.close
    FileUtils.rm file.path
  end
end
