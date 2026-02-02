defmodule PdfTipsElixirWeb.CarbonIcons do
  @moduledoc """
  IBM Carbon Design System icons for Phoenix.

  All icons sourced from the official Carbon repository:
  https://github.com/carbon-design-system/carbon/tree/main/packages/icons/src/svg/32

  Usage: <.carbon_icon name="dashboard" class="w-5 h-5" />
  """
  use Phoenix.Component
  import Phoenix.HTML, only: [raw: 1]

  @doc """
  Renders a Carbon icon.

  ## Examples

      <.carbon_icon name="dashboard" />
      <.carbon_icon name="document" class="w-6 h-6 text-primary" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: "w-5 h-5"
  attr :rest, :global

  def carbon_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 32 32"
      fill="currentColor"
      class={@class}
      {@rest}
    >
      {raw(icon_paths(@name))}
    </svg>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/AI.svg
  defp icon_paths("ai") do
    """
    <polygon points="17 11 20 11 20 21 17 21 17 23 25 23 25 21 22 21 22 11 25 11 25 9 17 9 17 11"/>
    <path d="m13,9h-4c-1.103,0-2,.897-2,2v12h2v-5h4v5h2v-12c0-1.103-.897-2-2-2Zm-4,7v-5h4v5h-4Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/dashboard.svg
  defp icon_paths("dashboard") do
    """
    <rect x="24" y="21" width="2" height="5"/>
    <rect x="20" y="16" width="2" height="10"/>
    <path d="M11,26a5.0059,5.0059,0,0,1-5-5H8a3,3,0,1,0,3-3V16a5,5,0,0,1,0,10Z"/>
    <path d="M28,2H4A2.002,2.002,0,0,0,2,4V28a2.0023,2.0023,0,0,0,2,2H28a2.0027,2.0027,0,0,0,2-2V4A2.0023,2.0023,0,0,0,28,2Zm0,9H14V4H28ZM12,4v7H4V4ZM4,28V13H28.0007l.0013,15Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/document.svg
  defp icon_paths("document") do
    """
    <path d="M25.7,9.3l-7-7C18.5,2.1,18.3,2,18,2H8C6.9,2,6,2.9,6,4v24c0,1.1,0.9,2,2,2h16c1.1,0,2-0.9,2-2V10C26,9.7,25.9,9.5,25.7,9.3z M18,4.4l5.6,5.6H18V4.4z M24,28H8V4h8v6c0,1.1,0.9,2,2,2h6V28z"/>
    <rect x="10" y="22" width="12" height="2"/>
    <rect x="10" y="16" width="12" height="2"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/idea.svg
  defp icon_paths("idea") do
    """
    <rect x="11" y="24" width="10" height="2"/>
    <rect x="13" y="28" width="6" height="2"/>
    <path d="M16,2A10,10,0,0,0,6,12a9.19,9.19,0,0,0,3.46,7.62c1,.93,1.54,1.46,1.54,2.38h2c0-1.84-1.11-2.87-2.19-3.86A7.2,7.2,0,0,1,8,12a8,8,0,0,1,16,0,7.2,7.2,0,0,1-2.82,6.14c-1.07,1-2.18,2-2.18,3.86h2c0-.92.53-1.45,1.54-2.39A9.18,9.18,0,0,0,26,12,10,10,0,0,0,16,2Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/settings.svg
  defp icon_paths("settings") do
    """
    <path d="M27,16.76c0-.25,0-.5,0-.76s0-.51,0-.77l1.92-1.68A2,2,0,0,0,29.3,11L26.94,7a2,2,0,0,0-1.73-1,2,2,0,0,0-.64.1l-2.43.82a11.35,11.35,0,0,0-1.31-.75l-.51-2.52a2,2,0,0,0-2-1.61H13.64a2,2,0,0,0-2,1.61l-.51,2.52a11.48,11.48,0,0,0-1.32.75L7.43,6.06A2,2,0,0,0,6.79,6,2,2,0,0,0,5.06,7L2.7,11a2,2,0,0,0,.41,2.51L5,15.24c0,.25,0,.5,0,.76s0,.51,0,.77L3.11,18.45A2,2,0,0,0,2.7,21L5.06,25a2,2,0,0,0,1.73,1,2,2,0,0,0,.64-.1l2.43-.82a11.35,11.35,0,0,0,1.31.75l.51,2.52a2,2,0,0,0,2,1.61h4.72a2,2,0,0,0,2-1.61l.51-2.52a11.48,11.48,0,0,0,1.32-.75l2.42.82a2,2,0,0,0,.64.1,2,2,0,0,0,1.73-1L29.3,21a2,2,0,0,0-.41-2.51ZM25.21,24l-3.43-1.16a8.86,8.86,0,0,1-2.71,1.57L18.36,28H13.64l-.71-3.55a9.36,9.36,0,0,1-2.7-1.57L6.79,24,4.43,20l2.72-2.4a8.9,8.9,0,0,1,0-3.13L4.43,12,6.79,8l3.43,1.16a8.86,8.86,0,0,1,2.71-1.57L13.64,4h4.72l.71,3.55a9.36,9.36,0,0,1,2.7,1.57L25.21,8,27.57,12l-2.72,2.4a8.9,8.9,0,0,1,0,3.13L27.57,20Z"/>
    <path d="M16,22a6,6,0,1,1,6-6A5.94,5.94,0,0,1,16,22Zm0-10a3.91,3.91,0,0,0-4,4,3.91,3.91,0,0,0,4,4,3.91,3.91,0,0,0,4-4A3.91,3.91,0,0,0,16,12Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/light.svg
  defp icon_paths("light") do
    """
    <rect x="15" y="2" width="2" height="5"/>
    <rect x="21.6675" y="6.8536" width="4.958" height="1.9998" transform="translate(1.5191 19.3744) rotate(-45)"/>
    <rect x="25" y="15" width="5" height="2"/>
    <rect x="23.1466" y="21.6675" width="1.9998" height="4.958" transform="translate(-10.0018 24.1465) rotate(-45)"/>
    <rect x="15" y="25" width="2" height="5"/>
    <rect x="5.3745" y="23.1466" width="4.958" height="1.9998" transform="translate(-14.7739 12.6256) rotate(-45)"/>
    <rect x="2" y="15" width="5" height="2"/>
    <rect x="6.8536" y="5.3745" width="1.9998" height="4.958" transform="translate(-3.253 7.8535) rotate(-45)"/>
    <path d="M16,12a4,4,0,1,1-4,4,4.0045,4.0045,0,0,1,4-4m0-2a6,6,0,1,0,6,6,6,6,0,0,0-6-6Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/asleep.svg
  defp icon_paths("asleep") do
    """
    <path d="M13.5025,5.4136A15.0755,15.0755,0,0,0,25.096,23.6082a11.1134,11.1134,0,0,1-7.9749,3.3893c-.1385,0-.2782.0051-.4178,0A11.0944,11.0944,0,0,1,13.5025,5.4136M14.98,3a1.0024,1.0024,0,0,0-.1746.0156A13.0959,13.0959,0,0,0,16.63,28.9973c.1641.006.3282,0,.4909,0a13.0724,13.0724,0,0,0,10.702-5.5556,1.0094,1.0094,0,0,0-.7833-1.5644A13.08,13.08,0,0,1,15.8892,4.38,1.0149,1.0149,0,0,0,14.98,3Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/checkmark--filled.svg
  defp icon_paths("checkmark-filled") do
    """
    <path d="M16,2A14,14,0,1,0,30,16,14,14,0,0,0,16,2ZM14,21.5908l-5-5L10.5906,15,14,18.4092,21.41,11l1.5957,1.5859Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/warning.svg
  defp icon_paths("warning") do
    """
    <path d="M16,2A14,14,0,1,0,30,16,14,14,0,0,0,16,2Zm0,26A12,12,0,1,1,28,16,12,12,0,0,1,16,28Z"/>
    <rect x="15" y="8" width="2" height="11"/>
    <path d="M16,22a1.5,1.5,0,1,0,1.5,1.5A1.5,1.5,0,0,0,16,22Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/warning--filled.svg
  defp icon_paths("warning-filled") do
    """
    <path d="M16,2C8.3,2,2,8.3,2,16s6.3,14,14,14s14-6.3,14-14C30,8.3,23.7,2,16,2z M14.9,8h2.2v11h-2.2V8z M16,25c-0.8,0-1.5-0.7-1.5-1.5S15.2,22,16,22c0.8,0,1.5,0.7,1.5,1.5S16.8,25,16,25z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/information--filled.svg
  defp icon_paths("information-filled") do
    """
    <path d="M16,2A14,14,0,1,0,30,16,14,14,0,0,0,16,2Zm0,6a1.5,1.5,0,1,1-1.5,1.5A1.5,1.5,0,0,1,16,8Zm4,16.125H12v-2.25h2.875v-5.75H13v-2.25h4.125v8H20Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/password.svg (key icon)
  defp icon_paths("key") do
    """
    <path d="M21,2a8.9977,8.9977,0,0,0-8.6119,11.6118L2,24v6H8L18.3881,19.6118A9,9,0,1,0,21,2Zm0,16a7.0125,7.0125,0,0,1-2.0322-.3022L17.821,17.35l-.8472.8472-3.1811,3.1812L12.4141,20,11,21.4141l1.3787,1.3786-1.5859,1.586L9.4141,23,8,24.4141l1.3787,1.3786L7.1716,28H4V24.8284l9.8023-9.8023.8472-.8474-.3473-1.1467A7,7,0,1,1,21,18Z"/>
    <circle cx="22" cy="10" r="2"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/send.svg
  defp icon_paths("send") do
    """
    <path d="M27.45,15.11l-22-11a1,1,0,0,0-1.08.12,1,1,0,0,0-.33,1L7,16,4,26.74A1,1,0,0,0,5,28a1,1,0,0,0,.45-.11l22-11a1,1,0,0,0,0-1.78Zm-20.9,10L8.76,17H18V15H8.76L6.55,6.89,24.76,16Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/renew.svg (refresh)
  defp icon_paths("refresh") do
    """
    <path d="M12,10H6.78A11,11,0,0,1,27,16h2A13,13,0,0,0,6,7.68V4H4v8h8Z"/>
    <path d="M20,22h5.22A11,11,0,0,1,5,16H3a13,13,0,0,0,23,8.32V28h2V20H20Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/time.svg
  defp icon_paths("time") do
    """
    <path d="M16,30A14,14,0,1,1,30,16,14,14,0,0,1,16,30ZM16,4A12,12,0,1,0,28,16,12,12,0,0,0,16,4Z"/>
    <polygon points="20.59 22 15 16.41 15 7 17 7 17 15.58 22 20.59 20.59 22"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/data--base.svg
  defp icon_paths("data-base") do
    """
    <path d="M24,3H8A2,2,0,0,0,6,5V27a2,2,0,0,0,2,2H24a2,2,0,0,0,2-2V5A2,2,0,0,0,24,3Zm0,2v6H8V5ZM8,19V13H24v6Zm0,8V21H24v6Z"/>
    <circle cx="11" cy="8" r="1"/>
    <circle cx="11" cy="16" r="1"/>
    <circle cx="11" cy="24" r="1"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/link.svg
  defp icon_paths("link") do
    """
    <path d="M29.25,6.76a6,6,0,0,0-8.5,0l1.42,1.42a4,4,0,1,1,5.67,5.67l-8,8a4,4,0,1,1-5.67-5.66l1.41-1.42-1.41-1.42-1.42,1.42a6,6,0,0,0,0,8.5A6,6,0,0,0,17,25a6,6,0,0,0,4.27-1.76l8-8A6,6,0,0,0,29.25,6.76Z"/>
    <path d="M4.19,24.82a4,4,0,0,1,0-5.67l8-8a4,4,0,0,1,5.67,0A3.94,3.94,0,0,1,19,14a4,4,0,0,1-1.17,2.85L15.71,19l1.42,1.42,2.12-2.12a6,6,0,0,0-8.51-8.51l-8,8a6,6,0,0,0,0,8.51A6,6,0,0,0,7,28a6.07,6.07,0,0,0,4.28-1.76L9.86,24.82A4,4,0,0,1,4.19,24.82Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/document--pdf.svg
  defp icon_paths("pdf") do
    """
    <polygon points="30 18 30 16 24 16 24 26 26 26 26 22 29 22 29 20 26 20 26 18 30 18"/>
    <path d="M19,26H15V16h4a3.0033,3.0033,0,0,1,3,3v4A3.0033,3.0033,0,0,1,19,26Zm-2-2h2a1.0011,1.0011,0,0,0,1-1V19a1.0011,1.0011,0,0,0-1-1H17Z"/>
    <path d="M11,16H6V26H8V23h3a2.0027,2.0027,0,0,0,2-2V18A2.0023,2.0023,0,0,0,11,16ZM8,21V18h3l.001,3Z"/>
    <path d="M22,14V10a.9092.9092,0,0,0-.3-.7l-7-7A.9087.9087,0,0,0,14,2H4A2.0059,2.0059,0,0,0,2,4V28a2,2,0,0,0,2,2H20V28H4V4h8v6a2.0059,2.0059,0,0,0,2,2h6v2Zm-8-4V4.4L19.6,10Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/cube.svg
  defp icon_paths("cube") do
    """
    <path d="M28.5039,8.1362l-12-7a1,1,0,0,0-1.0078,0l-12,7A1,1,0,0,0,3,9V23a1,1,0,0,0,.4961.8638l12,7a1,1,0,0,0,1.0078,0l12-7A1,1,0,0,0,29,23V9A1,1,0,0,0,28.5039,8.1362ZM16,3.1577,26.0156,9,16,14.8423,5.9844,9ZM5,10.7412l10,5.833V28.2588L5,22.4258ZM17,28.2588V16.5742l10-5.833V22.4258Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/arrow--left.svg
  defp icon_paths("arrow-left") do
    """
    <polygon points="14 26 15.41 24.59 7.83 17 28 17 28 15 7.83 15 15.41 7.41 14 6 4 16 14 26"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/trash-can.svg
  defp icon_paths("trash-can") do
    """
    <rect x="12" y="12" width="2" height="12"/>
    <rect x="18" y="12" width="2" height="12"/>
    <path d="M4,6V8H6V28a2,2,0,0,0,2,2H24a2,2,0,0,0,2-2V8h2V6ZM8,28V8H24V28Z"/>
    <rect x="12" y="2" width="8" height="2"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/close.svg
  defp icon_paths("close") do
    """
    <polygon points="17.4141 16 24 9.4141 22.5859 8 16 14.5859 9.4143 8 8 9.4141 14.5859 16 8 22.5859 9.4143 24 16 17.4141 22.5859 24 24 22.5859 17.4141 16"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/search.svg
  defp icon_paths("search") do
    """
    <path d="M29,27.5859l-7.5521-7.5521a11.0177,11.0177,0,1,0-1.4141,1.4141L27.5859,29ZM4,13a9,9,0,1,1,9,9A9.01,9.01,0,0,1,4,13Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/tag.svg
  defp icon_paths("tag") do
    """
    <path d="M10,14a4,4,0,1,1,4-4A4.0045,4.0045,0,0,1,10,14Zm0-6a2,2,0,1,0,1.998,2.0044A2.002,2.002,0,0,0,10,8Z"/>
    <path d="M16.6436,29.4145,2.5858,15.3555A2,2,0,0,1,2,13.9414V4A2,2,0,0,1,4,2h9.9413a2,2,0,0,1,1.4142.5858L29.4144,16.6436a2.0005,2.0005,0,0,1,0,2.8285l-9.9424,9.9425a2.0008,2.0008,0,0,1-2.8285,0ZM4,4v9.9417L18.0578,28,28,18.0579,13.9416,4Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/folder.svg
  defp icon_paths("folder") do
    """
    <path d="M11.17,6l3.42,3.41.58.59H28V26H4V6h7.17m0-2H4A2,2,0,0,0,2,6V26a2,2,0,0,0,2,2H28a2,2,0,0,0,2-2V10a2,2,0,0,0-2-2H16L12.59,4.59A2,2,0,0,0,11.17,4Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/lightning.svg
  defp icon_paths("lightning") do
    """
    <path d="M11.61,29.92a1,1,0,0,1-.6-1.07L12.83,17H8a1,1,0,0,1-1-1.23l3-13A1,1,0,0,1,11,2H21a1,1,0,0,1,.78.37,1,1,0,0,1,.2.85L20.25,11H25a1,1,0,0,1,.9.56,1,1,0,0,1-.11,1l-13,17A1,1,0,0,1,12,30,1.09,1.09,0,0,1,11.61,29.92ZM17.75,13l2-9H11.8L9.26,15h5.91L13.58,25.28,23,13Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/cloud--upload.svg
  defp icon_paths("cloud-upload") do
    """
    <polygon points="11 18 12.41 19.41 15 16.83 15 29 17 29 17 16.83 19.59 19.41 21 18 16 13 11 18"/>
    <path d="M23.5,22H23V20h.5a4.5,4.5,0,0,0,.36-9L23,11l-.1-.82a7,7,0,0,0-13.88,0L9,11,8.14,11a4.5,4.5,0,0,0,.36,9H9v2H8.5A6.5,6.5,0,0,1,7.2,9.14a9,9,0,0,1,17.6,0A6.5,6.5,0,0,1,23.5,22Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/home.svg
  defp icon_paths("home") do
    """
    <path d="M16.6123,2.2138a1.01,1.01,0,0,0-1.2427,0L1,13.4194l1.2427,1.5717L4,13.6209V26a2.0041,2.0041,0,0,0,2,2H26a2.0037,2.0037,0,0,0,2-2V13.63L29.7573,15,31,13.4282ZM18,26H14V18h4Zm2,0V18a2.0023,2.0023,0,0,0-2-2H14a2.002,2.002,0,0,0-2,2v8H6V12.0615l10-7.79,10,7.8005V26Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/chat.svg
  defp icon_paths("chat") do
    """
    <path d="M17.74,30,16,29l4-7h6a2,2,0,0,0,2-2V8a2,2,0,0,0-2-2H6A2,2,0,0,0,4,8V20a2,2,0,0,0,2,2h9v2H6a4,4,0,0,1-4-4V8A4,4,0,0,1,6,4H26a4,4,0,0,1,4,4V20a4,4,0,0,1-4,4H21.16Z"/>
    <rect x="8" y="10" width="16" height="2"/>
    <rect x="8" y="16" width="10" height="2"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/book.svg
  defp icon_paths("book") do
    """
    <rect x="19" y="10" width="7" height="2"/>
    <rect x="19" y="15" width="7" height="2"/>
    <rect x="19" y="20" width="7" height="2"/>
    <rect x="6" y="10" width="7" height="2"/>
    <rect x="6" y="15" width="7" height="2"/>
    <rect x="6" y="20" width="7" height="2"/>
    <path d="M28,5H4A2.002,2.002,0,0,0,2,7V25a2.002,2.002,0,0,0,2,2H28a2.002,2.002,0,0,0,2-2V7A2.002,2.002,0,0,0,28,5ZM4,7H15V25H4ZM17,25V7H28V25Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/cloud.svg
  defp icon_paths("cloud") do
    """
    <path d="M16,7h0a7.66,7.66,0,0,1,1.51.15,8,8,0,0,1,6.35,6.34l.26,1.35,1.35.24a5.5,5.5,0,0,1-1,10.92H7.5a5.5,5.5,0,0,1-1-10.92l1.34-.24.26-1.35A8,8,0,0,1,16,7m0-2a10,10,0,0,0-9.83,8.12A7.5,7.5,0,0,0,7.49,28h17a7.5,7.5,0,0,0,1.32-14.88,10,10,0,0,0-7.94-7.94A10.27,10.27,0,0,0,16,5Z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/edit.svg
  defp icon_paths("edit") do
    """
    <rect x="2" y="26" width="28" height="2"/>
    <path d="M25.4,9c0.8-0.8,0.8-2,0-2.8c0,0,0,0,0,0l-3.6-3.6c-0.8-0.8-2-0.8-2.8,0c0,0,0,0,0,0l-15,15V24h6.4L25.4,9z M20.4,4L24,7.6l-3,3L17.4,7L20.4,4z M6,22v-3.6l10-10l3.6,3.6l-10,10H6z"/>
    """
  end

  # Official: https://github.com/carbon-design-system/carbon/blob/main/packages/icons/src/svg/32/checkmark--outline.svg
  defp icon_paths("checkmark-outline") do
    """
    <polygon points="14 21.414 9 16.413 10.413 15 14 18.586 21.585 11 23 12.415 14 21.414"/>
    <path d="M16,2A14,14,0,1,0,30,16,14,14,0,0,0,16,2Zm0,26A12,12,0,1,1,28,16,12,12,0,0,1,16,28Z"/>
    """
  end

  # Fallback for unknown icons - shows a placeholder square
  defp icon_paths(_name) do
    """
    <rect x="6" y="6" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2"/>
    <line x1="6" y1="6" x2="26" y2="26" stroke="currentColor" stroke-width="2"/>
    <line x1="26" y1="6" x2="6" y2="26" stroke="currentColor" stroke-width="2"/>
    """
  end
end
